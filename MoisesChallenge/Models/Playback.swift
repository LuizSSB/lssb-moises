//
//  Playback.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

enum PlaybackQueueDirection {
    case previous,
         next
}

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(String)
}

