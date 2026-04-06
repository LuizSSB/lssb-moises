//
//  AlbumViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Observation

protocol AlbumViewModel: ViewModel {
    var album: ActionStatus<Album, UserFacingError> { get }
    var observableSelectedSong: ObservedData<Song>? { get }
    
    func onAppear()
    func onDisappear()
    func loadAlbum()
    func select(song: Song)
}
