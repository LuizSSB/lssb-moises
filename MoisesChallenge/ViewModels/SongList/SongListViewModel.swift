//
//  SongListViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Foundation
import Observation

private let defaultSizePage = 1

@MainActor
@Observable
final class SongListViewModel {
    private(set) var recentList: PaginatedListViewModel<Song, NullPaginationParams>
    
    var searchText = ""
    private var currentQuery = ""
    private(set) var searchList: PaginatedListViewModel<Song, SongSearchService.SearchParams>?
    
    private(set) var player = PresentationViewModel<SongPlayerViewModel>()
    private(set) var album = PresentationViewModel<AlbumViewModel>()

    private let service: SongSearchService

    init(service: SongSearchService) {
        self.service = service
        self.recentList = PaginatedListViewModel(
            fetch: { @MainActor in
                let result = try await service.search(
                    .init(
                        params: .init(searchTerm: "foo"),
                        offset: $0?.offset ?? 0,
                        limit: $0?.limit ?? 10
                    )
                )
                return .init(
                    entries: result.entries,
                    pagination: .init(
                        params: .instance,
                        offset: result.pagination.offset,
                        limit: result.pagination.limit
                    )
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
        album.present(.init(albumId: albumId, service: .init()))
    }
    
    private func fetchSearch(
        page: Pagination<SongSearchService.SearchParams>?
    ) async throws -> Pagination<SongSearchService.SearchParams>.Page<Song> {
        try await service.search(
            page
            ?? .first(
                params: .init(searchTerm: searchText),
                limit: defaultSizePage
            )
        )
    }
}
