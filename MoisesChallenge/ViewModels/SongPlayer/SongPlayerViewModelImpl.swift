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
    private(set) var progress: Double = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var duration: TimeInterval?
    private(set) var album: any PresentationViewModel<any AlbumViewModel> = PresentationViewModelImpl()
    
    // MARK: - Private state
    
    private let queue: any SongPlayerQueue
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemObservation: Task<Void, Never>?
    private var queueWatchTask: Task<Void, Never>?
    private var lifetimeTasks = Set<Task<Void, Never>>()
    
    private let interactionService: InteractionService
    
    // MARK: - Lifecycle
    
    init(queue: any SongPlayerQueue, interactionService: InteractionService) {
        self.queue = queue
        self.interactionService = interactionService
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
        
        // TODO: if error, show message?
//        let loadedMoreEvent = queue.loadedMoreEvent
//        lifetimeTasks.insert(Task { [weak self] in
//            for await (direction, result) in await loadedMoreEvent.stream().stream {
//                guard let self else { return }
//                
//                guard direction != nil,
//                      case let .failure(error) = result
//                else { continue }
//            }
//        })
    }
    
    func onDisappear() {
        pause()
        queueWatchTask?.cancel()
        queueWatchTask = nil
        lifetimeTasks.removeAll()
    }
    
    // MARK: - Extra
    func onSelectAlbum(of song: Song) {
        guard let albumId = song.album?.id else { return }
        let viewModel: any AlbumViewModel = AlbumViewModelImpl(albumId: albumId, service: .iTunes)
        album.present(viewModel)
    }
    
    // MARK: - Controls
    
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool {
        queue.isLoading(direction)
    }
    
    func has(_ direction: PlaybackQueueDirection) -> Bool {
        queue.has(direction)
    }
    
    func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused, .idle, .error:
            play()
        case .loading:
            break
        }
    }
    
    func seek(to fraction: Double) {
        guard let duration = player?.currentItem?.duration,
              duration.isNumeric else { return }
        let seconds = duration.seconds * fraction
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }
    
    func move(to direction: PlaybackQueueDirection) {
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
        
        // Not meant to happen. Would it make sense to move to next song?
        guard let url = song.previewURL else {
            withAnimation {
                playbackState = .paused
            }
            return
        }
        
        withAnimation {
            playbackState = .loading
        }
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        
        observePlayerItem(item)
        attachTimeObserver(to: newPlayer)
        
        newPlayer.play()
        
        withAnimation {
            playbackState = .playing
        }
    }
    
    private func play() {
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
        
        if progress >= 1 && queue.has(.next) {
            queue.move(to: .next)
        }
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
                    let message = item.error?.localizedDescription ?? "Playback failed"
                    withAnimation {
                        self.playbackState = .error(message)
                    }
                default:
                    break
                }
            }
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
