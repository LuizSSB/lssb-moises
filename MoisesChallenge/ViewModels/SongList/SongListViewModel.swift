//
//  SongListViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Foundation
import Observation

private let defaultSizePage = 10

@MainActor
@Observable
final class SongListViewModel {
    private(set) var recentList: PaginatedListViewModel<Song, NullPaginationParams>
    
    var searchText = ""
    private var currentQuery = ""
    private(set) var searchList: PaginatedListViewModel<Song, SongSearchService.SearchParams>?
    
    private(set) var player = PresentationViewModel<SongPlayerViewModel>()
    private(set) var album = PresentationViewModel<AlbumViewModel>()

    private let songService: SongSearchService

    init(interactionService: InteractionService, songService: SongSearchService) {
        self.songService = songService
        self.recentList = PaginatedListViewModel(
            fetch: {
                let page = try await interactionService.listPlayedSongs($0 ?? .first())
                return .init(
                    entries: page.entries.map(\.song),
                    pagination: page.pagination
                )
            }
        )
    }

    func onAppear() {
        guard searchList == nil else { return }
        recentList.loadFirstPageIfNeeded()
    }

    func onSearchBar(focused: Bool) {
        if focused {
            guard searchList == nil else { return }
            searchList = .init(fetch: fetchSearch)
        } else {
            guard searchList != nil else { return }
            searchList = nil
            searchText = ""
            currentQuery = ""
            Task {
                await recentList.refresh()
            }
        }
    }
    
    func onSearchSubmitted() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty,
              query != currentQuery,
              let searchList
        else { return }
        
        currentQuery = query
        Task {
            await searchList.refresh()
        }
    }
    
    func onSelect(song: Song) {
        let queue: any MoisesChallenge.SongPlayerQueue = if let searchList {
            SongPlayerQueue(list: searchList, selectedSong: song)
        } else {
            SongPlayerQueue(list: recentList, selectedSong: song)
        }
        player.present(.init(queue: queue))
    }
    
    func onSelectAlbum(of song: Song) {
        guard let albumId = song.album?.id else { return }
        album.present(.init(albumId: albumId, service: .iTunes))
    }
    
    private func fetchSearch(
        page: Pagination<SongSearchService.SearchParams>?
    ) async throws -> Pagination<SongSearchService.SearchParams>.Page<Song> {
        try await songService.search(
            page
            ?? .first(
                params: .init(searchTerm: searchText),
                limit: defaultSizePage
            )
        )
    }
}
