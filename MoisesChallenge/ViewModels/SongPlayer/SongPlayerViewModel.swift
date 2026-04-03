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
    var progress: Double { get }
    var elapsed: TimeInterval { get }
    var duration: TimeInterval? { get } // nil until it's resolved it
    var album: any PresentationViewModel<AlbumViewModel> { get }
    
    func onAppear()
    func onDisappear()
    func onSelectAlbum(of song: Song)
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool
    func has(_ direction: PlaybackQueueDirection) -> Bool
    func togglePlayPause()
    func seek(to fraction: Double)
    func move(to direction: PlaybackQueueDirection)
}
