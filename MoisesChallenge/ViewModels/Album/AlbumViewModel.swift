//
//  AlbumViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Observation

@MainActor
protocol AlbumViewModel: AnyObject, Observable, Sendable {
    var album: ActionStatus<Album, UserFacingError> { get }
    var playbackRequiredEvent: Event<any PlaybackQueue> { get }
    
    func onAppear()
    func onDisappear()
    func loadAlbum()
    func select(song: Song)
}
