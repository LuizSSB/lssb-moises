//
//  SongPlayerViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

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
    private let playbackController: any SongPlaybackController
    private var queueWatchTask: Task<Void, Never>?
    private var lifetimeTasks = Set<Task<Void, Never>>()
    
    private let interactionService: InteractionService
    private let container: any IoCContainer
    
    // MARK: - Lifecycle
    
    init(
        queue: any PlaybackQueue<Song>,
        playbackController: any SongPlaybackController,
        interactionService: InteractionService,
        container: any IoCContainer
    ) {
        self.queue = queue
        self.playbackController = playbackController
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
                        guard self.repeatMode != .current else { return }
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
        
        let playbackEvent = playbackController.event
        lifetimeTasks.insert(Task { [weak self] in
            for await event in await playbackEvent.stream().stream {
                guard let self else { return }
                await MainActor.run {
                    self.handlePlaybackEvent(event)
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
        playbackController.seek(to: fraction)
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
        
        withAnimation {
            playbackState = .loading
        }
        playbackController.load(song)
    }
    
    private func play() {
        guard currentSong != nil else { return }
        playbackController.play()
        playbackState = .playing
    }
    
    private func pause() {
        playbackController.pause()
        if case .playing = playbackState {
            playbackState = .paused
        }
    }
    
    private func stopCurrentPlayback() {
        playbackController.stop()
    }

    private func handlePlaybackEvent(_ event: SongPlaybackControllerEvent) {
        switch event {
        case .readyToPlay:
            guard let song = currentSong else { return }
            Task {
                try? await interactionService.markPlayed(song)
            }
            
            if playbackState == .loading {
                withAnimation {
                    playbackState = .playing
                }
            }
            
        case let .progress(currentElapsed, totalDuration):
            guard totalDuration > 0 else { return }
            duration = totalDuration
            elapsed = currentElapsed
            progress = currentElapsed / totalDuration
            
        case .didFinishPlaying:
            playbackState = .paused
            handlePlaybackEnded()
            
        case .failed:
            failCurrentSongLoad()
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
        playbackController.restart()
        withAnimation {
            playbackState = .playing
            elapsed = 0
            progress = 0
        }
    }

    private func failCurrentSongLoad() {
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
