//
//  SongListViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Observation

@MainActor
protocol SongListViewModel: AnyObject, Observable, Sendable {
    var recentList: any PaginatedListViewModel<Song, NullPaginationParams> { get }
    
    var workingSearchQuery: String { get set }
    var currentQuery: String { get }
    var searchList: (any PaginatedListViewModel<Song, SongSearchParams>)? { get }
    
    var currentList: any BasePaginatedListViewModel<Song> { get }
    
    var player: any PresentationViewModel<any SongPlayerViewModel> { get }
    var album: any PresentationViewModel<any AlbumViewModel> { get }
    
    func onAppear()
    func handleSearchBar(focused: Bool)
    func submitSearch()
    func select(song: Song)
    func selectAlbum(of song: Song)
}
