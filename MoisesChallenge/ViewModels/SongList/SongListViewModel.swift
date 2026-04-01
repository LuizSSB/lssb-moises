//
//  SongListViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class SongListViewModel {
    private(set) var recentList: PaginatedListViewModel<Song, NullPaginationParams>
    private(set) var searchList: PaginatedListViewModel<Song, SongDataSource.SearchParams>?
    var searchText = ""
    var playerQueue: (any SongPlayerQueue)?

    private let dataSource: SongDataSource

    init(dataSource: SongDataSource) {
        self.dataSource = dataSource
        self.recentList = PaginatedListViewModel(
            fetch: {
                .init(entries: [], pagination: $0 ?? .first())
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
            recentList.refresh()
        }
    }
    
    func onSearchSubmitted() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, let searchList else { return }
        searchList.refresh()
    }
    
    func onSelect(song: Song) {
        playerQueue = if let searchList {
            SongListPlayerQueue(list: searchList, selectedSong: song)
        } else {
            SongListPlayerQueue(list: recentList, selectedSong: song)
        }
    }
    
    func onDismissPlayer() {
        playerQueue = nil
    }
    
    private func fetchSearch(
        page: Pagination<SongDataSource.SearchParams>?
    ) async throws -> Pagination<SongDataSource.SearchParams>.Page<Song> {
        try await dataSource.search(page ?? .first(params: .init(searchTerm: searchText)))
    }
}
