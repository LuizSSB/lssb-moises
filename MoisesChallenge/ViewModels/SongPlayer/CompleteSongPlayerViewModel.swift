//
//  CompleteSongPlayerViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

@MainActor
protocol CompleteSongPlayerViewModel: AnyObject {
    var actualPlayer: any FocusedSongPlayerViewModel { get }
    var songList: any PaginatedListViewModel<Song> { get }
    var album: any PresentationViewModel<any AlbumViewModel> { get }
    
    func select(song: Song)
    func selectAlbum(of song: Song)
}
