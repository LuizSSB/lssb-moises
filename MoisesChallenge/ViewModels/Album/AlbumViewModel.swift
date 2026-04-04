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
    var player: any PresentationViewModel<any SongPlayerViewModel> { get }
    
    func onAppear()
    func onDisappear()
    func loadAlbum()
    func select(song: Song)
}
