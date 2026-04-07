//
//  AVSongPlaybackController.swift
//  MoisesChallenge
//
//  Created by Codex on 03/04/26.
//

import AVFoundation
import Foundation
import Observation

@Observable
final class AVSongPlaybackController: SongPlaybackController {
    private(set) var observableEvent: SongPlaybackControllerEvent?

    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private nonisolated(unsafe) var timeObserverToken: Any?
    @ObservationIgnored private var itemObservation: Task<Void, Never>?
    @ObservationIgnored private var playbackEndObservation: Task<Void, Never>?

    deinit {
        let currentPlayer = player
        currentPlayer?.pause()
        if let token = timeObserverToken {
            currentPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        itemObservation?.cancel()
        playbackEndObservation?.cancel()
        player = nil
    }

    func load(_ song: Song) {
        stop()
        configureAudioSession()

        guard let url = song.previewURL else {
            observableEvent = .failed
            return
        }

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer

        observePlayerItem(item)
        observePlaybackEnd(for: item)
        attachTimeObserver(to: newPlayer)

        newPlayer.play()
    }

    func play() {
        configureAudioSession()
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func seek(to fraction: Double) {
        guard let duration = player?.currentItem?.duration,
              duration.isNumeric else { return }
        let seconds = duration.seconds * fraction
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func restart() {
        guard let player else { return }

        player.seek(to: .zero) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                player.play()
                self.observableEvent = .progress(
                    elapsed: 0,
                    duration: player.currentItem?.duration.seconds ?? 0
                )
            }
        }
    }

    func stop() {
        teardownPlayback()
    }

    private func attachTimeObserver(to player: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        let token = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { [weak self] in
                await self?.updateProgress(currentTime: time)
            }
        }
        timeObserverToken = token
    }

    private func teardownPlayback() {
        let currentPlayer = player
        currentPlayer?.pause()
        if let token = timeObserverToken {
            currentPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        itemObservation?.cancel()
        itemObservation = nil
        playbackEndObservation?.cancel()
        playbackEndObservation = nil
        player = nil
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default)
        try? audioSession.setActive(true)
    }

    private func updateProgress(currentTime: CMTime) {
        guard let player else { return }
        guard let item = player.currentItem,
              item.duration.isNumeric
        else { return }

        let total = item.duration.seconds
        guard total > 0 else { return }

        observableEvent = .progress(elapsed: currentTime.seconds, duration: total)
    }

    private func observePlayerItem(_ item: AVPlayerItem) {
        itemObservation = Task { [weak self] in
            for await status in item.statusStream() {
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    await MainActor.run {
                        self.observableEvent = .readyToPlay
                    }
                case .failed:
                    await MainActor.run {
                        self.observableEvent = .failed
                    }
                default:
                    break
                }
            }
        }
    }

    private func observePlaybackEnd(for item: AVPlayerItem) {
        playbackEndObservation = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: AVPlayerItem.didPlayToEndTimeNotification,
                object: item
            )

            for await _ in notifications {
                guard let self else { return }
                await MainActor.run {
                    self.observableEvent = .didFinishPlaying
                }
            }
        }
    }
}

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
