//
//  FocusedSongPlayerViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Observation
import SwiftUI

@MainActor
@Observable
final class FocusedSongPlayerViewModelImpl: FocusedSongPlayerViewModel {
    // MARK: - Public state

    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentSong: Song?
    private(set) var repeatMode: PlaybackRepeatMode = .none
    private(set) var progress: Double = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var duration: TimeInterval?

    @ObservationIgnored private var hasStartedObserving = false

    // MARK: - Dependencies

    private let queue: any PlaybackQueue<Song>
    private let playbackController: any SongPlaybackController
    private let interactionService: InteractionService

    // MARK: - Lifecycle

    init(
        queue: any PlaybackQueue<Song>,
        playbackController: any SongPlaybackController,
        interactionService: InteractionService
    ) {
        self.queue = queue
        self.playbackController = playbackController
        self.interactionService = interactionService
    }

    func onAppear() {
        syncWithQueue()

        guard !hasStartedObserving else { return }
        hasStartedObserving = true

        observeQueue()
        observePlayback()
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
    
    func pause() {
        playbackController.pause()
        if case .playing = playbackState {
            playbackState = .paused
        }
    }

    func toggleRepeatMode() {
        let allModes = PlaybackRepeatMode.allCases

        guard let currentIndex = allModes.firstIndex(of: repeatMode) else {
            repeatMode = .none
            return
        }

        let nextIndex = allModes.index(after: currentIndex)
        repeatMode = nextIndex == allModes.endIndex ? allModes[0] : allModes[nextIndex]
    }

    func seek(to fraction: Double) {
        playbackController.seek(to: fraction)
    }

    func move(to direction: PlaybackQueueDirection) {
        Task { [weak self] in
            do {
                try await self?.queue.move(to: direction)
            } catch {
                guard let self else { return }
                guard direction == .next else { return }
                self.stopCurrentPlayback()
                withAnimation {
                    self.playbackState = .paused
                }
            }
        }
    }

    // MARK: - Queue Observation

    private func syncWithQueue() {
        let song = queue.currentItem
        guard song?.id != currentSong?.id else { return }
        loadSong(song)
    }

    private func observeQueue() {
        withObservationTracking {
            _ = queue.currentItem
        } onChangeAsync: { [weak self] in
            guard let self else { return }
            await self.observeQueue()
            await self.syncWithQueue()
        }
    }

    // MARK: - Playback

    private func observePlayback() {
        withObservationTracking {
            _ = playbackController.observableEvent
        } onChangeAsync: { [weak self] in
            guard let self else { return }
            await self.observePlayback()
            guard let event = await self.playbackController.observableEvent else { return }
            await self.handlePlaybackEvent(event)
        }
    }

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

    private func stopCurrentPlayback() {
        playbackController.stop()
    }

    private func handlePlaybackEvent(_ event: SongPlaybackControllerEvent) {
        switch event {
        case .readyToPlay:
            guard let currentSong else { return }
            Task {
                try? await interactionService.markPlayed(currentSong)
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
                move(to: .next)
            } else {
                pause()
                seek(to: 0)
            }
            
        case .current:
            restartCurrentSong()
            
        case .all:
            if queue.has(.next) {
                move(to: .next)
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
            move(to: .next)
            return
        }

        withAnimation {
            playbackState = .paused
        }
    }
}
