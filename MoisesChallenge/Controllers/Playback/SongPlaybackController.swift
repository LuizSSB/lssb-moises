//
//  SongPlaybackController.swift
//  MoisesChallenge
//
//  Created by Codex on 03/04/26.
//

import Foundation
import Observation

enum SongPlaybackControllerEvent: Sendable {
    case readyToPlay
    case progress(elapsed: TimeInterval, duration: TimeInterval)
    case didFinishPlaying
    case failed
}

@MainActor
protocol SongPlaybackController: AnyObject, Sendable, Observable {
    var observableEvent: SongPlaybackControllerEvent? { get }
    
    func load(_ song: Song)
    func play()
    func pause()
    func seek(to fraction: Double)
    func restart()
    func stop()
}
