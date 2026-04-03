//
//  SongPlayerViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import AVFoundation
import SwiftUI

@Observable
final class SongPlayerViewModelImpl: SongPlayerViewModel {
    // MARK: - Public state
    
    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentSong: Song?
    private(set) var repeatMode: PlaybackRepeatMode = .none
    private(set) var progress: Double = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var duration: TimeInterval?
    private(set) var album: any PresentationViewModel<any AlbumViewModel>
    
    // MARK: - Private state
    
    private let queue: any PlaybackQueue<Song>
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemObservation: Task<Void, Never>?
    private var playbackEndObservation: Task<Void, Never>?
    private var queueWatchTask: Task<Void, Never>?
    private var lifetimeTasks = Set<Task<Void, Never>>()
    
    private let interactionService: InteractionService
    private let container: any IoCContainer
    
    // MARK: - Lifecycle
    
    init(
        queue: any PlaybackQueue<Song>,
        interactionService: InteractionService,
        container: any IoCContainer
    ) {
        self.queue = queue
        self.interactionService = interactionService
        self.container = container
        self.album = container.presentationViewModel()
    }
    
    func onAppear() {
        syncWithQueue()
        
        guard lifetimeTasks.isEmpty else { return }
        
        let currentItemChangedEvent = queue.currentItemChangedEvent
        lifetimeTasks.insert(Task { [weak self] in
            for await _ in await currentItemChangedEvent.stream().stream {
                guard let self else { return }
                self.syncWithQueue()
            }
        })

        let loadedMoreEvent = queue.loadedMoreEvent
        lifetimeTasks.insert(Task { [weak self] in
            for await (songBatchStartIndex, result) in await loadedMoreEvent.stream().stream {
                guard let self else { return }
                guard self.queue.currentIndex == songBatchStartIndex - 1 else { continue }

                await MainActor.run {
                    switch result {
                    case .success:
                        self.handlePlaybackEnded()
                    case .failure:
                        self.stopCurrentPlayback()
                        withAnimation {
                            self.playbackState = .paused
                        }
                    }
                }
            }
        })
    }
    
    func onDisappear() {
        pause()
        queueWatchTask?.cancel()
        queueWatchTask = nil
        for task in lifetimeTasks {
            task.cancel()
        }
        lifetimeTasks.removeAll()
    }
    
    // MARK: - Extra
    func onSelectAlbum(of song: Song) {
        guard let albumId = song.album?.id else { return }
        let viewModel = container.albumViewModel(albumId: albumId)
        album.present(viewModel)
    }
    
    // MARK: - Controls
    
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool {
        queue.isLoading(direction)
    }
    
    func has(_ direction: PlaybackQueueDirection) -> Bool {
        queue.has(direction)
    }
    
    func onTogglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused, .idle, .error:
            play()
        case .loading:
            break
        }
    }
    
    func onToggleRepeatMode() {
        let allModes = PlaybackRepeatMode.allCases
        
        guard let currentIndex = allModes.firstIndex(of: repeatMode) else {
            repeatMode = .none
            return
        }
        
        let nextIndex = allModes.index(after: currentIndex)
        repeatMode = nextIndex == allModes.endIndex ? allModes[0] : allModes[nextIndex]
    }
    
    func onSeek(to fraction: Double) {
        guard let duration = player?.currentItem?.duration,
              duration.isNumeric else { return }
        let seconds = duration.seconds * fraction
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }
    
    func onMove(to direction: PlaybackQueueDirection) {
        queue.move(to: direction)
    }
    
    // MARK: - Private: queue observation
    
    private func syncWithQueue() {
        let song = queue.currentItem
        guard song?.id != currentSong?.id else { return }
        loadSong(song)
    }
    
    // MARK: - Private: playback
    
    private func loadSong(_ song: Song?) {
        stopCurrentPlayback()
        withAnimation {
            currentSong = song
            progress = 0
            elapsed = 0
            duration = nil
        }
        
        guard let song else {
            withAnimation {
                playbackState = .idle
            }
            return
        }
        
        guard let url = song.previewURL else {
            failCurrentSongLoad(with: InvalidDataError())
            return
        }
        
        withAnimation {
            playbackState = .loading
        }
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        
        observePlayerItem(item)
        observePlaybackEnd(for: item)
        attachTimeObserver(to: newPlayer)
        
        newPlayer.play()
        
        withAnimation {
            playbackState = .playing
        }
    }
    
    private func play() {
        guard player != nil else { return }
        player?.play()
        playbackState = .playing
    }
    
    private func pause() {
        player?.pause()
        if case .playing = playbackState {
            playbackState = .paused
        }
    }
    
    private func stopCurrentPlayback() {
        player?.pause()
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        itemObservation?.cancel()
        itemObservation = nil
        playbackEndObservation?.cancel()
        playbackEndObservation = nil
        player = nil
    }
    
    // MARK: - Private: time observation
    
    private func attachTimeObserver(to player: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        let token = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.updateProgress(currentTime: time, player: player)
            }
        }
        timeObserverToken = token
    }
    
    private func updateProgress(currentTime: CMTime, player: AVPlayer) {
        guard let item = player.currentItem,
              item.duration.isNumeric
        else { return }
        
        let total = item.duration.seconds
        guard total > 0 else { return }
        
        let current = currentTime.seconds
        duration = total
        elapsed = current
        progress = current / total
    }
    
    // MARK: - Private: item status observation
    
    private func observePlayerItem(_ item: AVPlayerItem) {
        itemObservation = Task { @MainActor [weak self] in
            for await status in item.statusStream() {
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    if let song = self.currentSong {
                        Task {
                            try? await self.interactionService.markPlayed(song)
                        }
                        
                        if self.playbackState == .loading {
                            withAnimation {
                                self.playbackState = .playing
                            }
                        }
                    }
                case .failed:
                    self.failCurrentSongLoad(with: item.error ?? InvalidDataError())
                default:
                    break
                }
            }
        }
    }
    
    private func observePlaybackEnd(for item: AVPlayerItem) {
        playbackEndObservation = Task { @MainActor [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: AVPlayerItem.didPlayToEndTimeNotification,
                object: item
            )
            
            for await _ in notifications {
                guard let self else { return }
                self.handlePlaybackEnded()
            }
        }
    }

    private func handlePlaybackEnded() {
        switch repeatMode {
        case .none:
            if queue.has(.next) {
                queue.move(to: .next)
            } else {
                pause()
                onSeek(to: 0)
            }
            
        case .current:
            restartCurrentSong()
            
        case .all:
            if queue.has(.next) {
                queue.move(to: .next)
            } else if queue.currentIndex == 0 {
                restartCurrentSong()
            } else {
                queue.currentIndex = 0
            }
        }
    }

    private func restartCurrentSong() {
        guard let player else { return }
        
        player.seek(to: .zero) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                player.play()
                withAnimation {
                    self.playbackState = .playing
                    self.elapsed = 0
                    self.progress = 0
                }
            }
        }
    }

    private func failCurrentSongLoad(with _: Error) {
        stopCurrentPlayback()

        if queue.has(.next) {
            queue.move(to: .next)
            return
        }

        withAnimation {
            playbackState = .paused
        }
    }
}

// MARK: - AVPlayerItem async status stream

private extension AVPlayerItem {
    func statusStream() -> AsyncStream<AVPlayerItem.Status> {
        AsyncStream { continuation in
            let observation = observe(\.status, options: [.new]) { item, _ in
                continuation.yield(item.status)
            }
            continuation.onTermination = { _ in
                observation.invalidate()
            }
        }
    }
}
