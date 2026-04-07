//
//  FocusedSongPlayerViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Foundation
import Observation

protocol FocusedSongPlayerViewModel: ViewModel {
    var playbackState: PlaybackState { get }
    var currentSong: Song? { get }
    var repeatMode: PlaybackRepeatMode { get }
    var progress: Double { get }
    var elapsed: TimeInterval { get }
    var duration: TimeInterval? { get } // nil until it's resolved it

    func onAppear()
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool
    func has(_ direction: PlaybackQueueDirection) -> Bool
    func togglePlayPause()
    func pause()
    func toggleRepeatMode()
    func seek(to fraction: Double)
    func move(to direction: PlaybackQueueDirection)
}
