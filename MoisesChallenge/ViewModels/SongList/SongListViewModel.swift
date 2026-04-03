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
    
    var searchText: String { get set }
    var currentQuery: String { get }
    var searchList: (any PaginatedListViewModel<Song, SongSearchParams>)? { get }
    
    var player: any PresentationViewModel<SongPlayerViewModel> { get }
    var album: any PresentationViewModel<AlbumViewModel> { get }
    
    func onAppear()
    func onSearchBar(focused: Bool)
    func onSearchSubmitted()
    func onSelect(song: Song)
    func onSelectAlbum(of song: Song)
}
