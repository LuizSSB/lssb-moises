//
//  SongPlayerViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import AVFoundation
import Observation
import Foundation

@MainActor
@Observable
final class SongPlayerViewModel {
    enum PlaybackState: Equatable {
        case idle
        case loading
        case playing
        case paused
        case error(String)
    }
    
    // MARK: - Public state
    
    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentSong: Song?
    private(set) var progress: Double = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var duration: TimeInterval? // nil until AVPlayer resolve it
    
    var hasPrevious: Bool {
        queue.hasPrevious
    }
    
    var hasNext: Bool {
        queue.hasNext
    }
    
    var isLoadingNext: Bool {
        queue.isLoadingNextForPlayer
    }
    
    // MARK: - Private state
    
    private let queue: any PlayerQueue
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemObservation: Task<Void, Never>?
    private var queueWatchTask: Task<Void, Never>?
    
    // MARK: - Lifecycle
    
    init(queue: any PlayerQueue) {
        self.queue = queue
    }
    
    func onAppear() {
        syncWithQueue()
        startWatchingQueue()
    }
    
    func onDisappear() {
        pause()
        queueWatchTask?.cancel()
        queueWatchTask = nil
    }
    
    // MARK: - Controls
    
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
    
    func previousSong() {
        queue.moveToPrevious()
        syncWithQueue()
    }
    
    func nextSong() {
        queue.moveToNext()
        syncWithQueue()
    }
    
    // MARK: - Private: queue observation
    
    private func startWatchingQueue() {
        queueWatchTask = Task { @MainActor [weak self] in
            // Poll using withObservationTracking to respond to @Observable changes
            // on the queue's currentItem.
            while !Task.isCancelled {
                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = self?.queue.currentItem
                        _ = self?.queue.isLoadingNextForPlayer
                    } onChange: {
                        continuation.resume()
                    }
                }
                guard !Task.isCancelled else { break }
                self?.syncWithQueue()
            }
        }
    }
    
    private func syncWithQueue() {
        let song = queue.currentItem
        guard song?.id != currentSong?.id else { return }
        loadSong(song)
    }
    
    // MARK: - Private: playback
    
    private func loadSong(_ song: Song?) {
        stopCurrentPlayback()
        currentSong = song
        progress = 0
        elapsed = 0
        duration = nil
        
        guard let song else {
            playbackState = .idle
            return
        }
        
        guard let url = song.previewURL else {
            // No preview URL — show as paused at 0, user can still navigate
            playbackState = .paused
            return
        }
        
        playbackState = .loading
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        
        observePlayerItem(item)
        attachTimeObserver(to: newPlayer)
        
        newPlayer.play()
        playbackState = .playing
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
    }
    
    // MARK: - Private: item status observation
    
    private func observePlayerItem(_ item: AVPlayerItem) {
        itemObservation = Task { @MainActor [weak self] in
            for await status in item.statusStream() {
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    if self.playbackState == .loading {
                        self.playbackState = .playing
                    }
                case .failed:
                    let message = item.error?.localizedDescription ?? "Playback failed"
                    self.playbackState = .error(message)
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
