//
//  CompleteSongPlayerViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

protocol CompleteSongPlayerViewModel: ViewModel {
    var actualPlayer: any FocusedSongPlayerViewModel { get }
    var songList: any PaginatedListViewModel<Song> { get }

    var observableSelectedAlbumId: ObservedData<String>? { get }

    func select(song: Song)
    func selectAlbum(of song: Song)
}
