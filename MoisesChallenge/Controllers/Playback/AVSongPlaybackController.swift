//
//  AVSongPlaybackController.swift
//  MoisesChallenge
//
//  Created by Codex on 03/04/26.
//

import AVFoundation
import Foundation

final class AVSongPlaybackController: SongPlaybackController {
    let event = Event<SongPlaybackControllerEvent>()
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemObservation: Task<Void, Never>?
    private var playbackEndObservation: Task<Void, Never>?
    
    deinit {
        itemObservation?.cancel()
        playbackEndObservation?.cancel()
    }
    
    func load(_ song: Song) {
        stop()
        
        guard let url = song.previewURL else {
            event.emitAndForget(.failed)
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
                self.event.emitAndForget(.progress(elapsed: 0, duration: player.currentItem?.duration.seconds ?? 0))
            }
        }
    }
    
    func stop() {
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
        
        event.emitAndForget(.progress(elapsed: currentTime.seconds, duration: total))
    }
    
    private func observePlayerItem(_ item: AVPlayerItem) {
        itemObservation = Task { [weak self] in
            for await status in item.statusStream() {
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    await self.event.emit(.readyToPlay)
                case .failed:
                    await self.event.emit(.failed)
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
                await self.event.emit(.didFinishPlaying)
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
