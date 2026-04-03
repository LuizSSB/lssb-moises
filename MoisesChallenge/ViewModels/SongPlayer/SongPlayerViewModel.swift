//
//  SongPlayerViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Foundation
import Observation

@MainActor
protocol SongPlayerViewModel: AnyObject, Observable, Sendable {
    var playbackState: PlaybackState { get }
    var currentSong: Song? { get }
    var repeatMode: PlaybackRepeatMode { get }
    var progress: Double { get }
    var elapsed: TimeInterval { get }
    var duration: TimeInterval? { get } // nil until it's resolved it
    var album: any PresentationViewModel<any AlbumViewModel> { get }
    
    func onAppear()
    func onDisappear()
    func onSelectAlbum(of song: Song)
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool
    func has(_ direction: PlaybackQueueDirection) -> Bool
    func onTogglePlayPause()
    func onToggleRepeatMode()
    func onSeek(to fraction: Double)
    func onMove(to direction: PlaybackQueueDirection)
}
