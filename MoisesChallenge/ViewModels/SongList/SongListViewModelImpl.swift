//
//  SongListViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Observation
import SwiftUI

@Observable
final class SongListViewModelImpl: SongListViewModel {
    // MARK: - Public State

    private(set) var recentList: any PaginatedListViewModel<Song>
    var workingSearchQuery = ""
    private(set) var currentQuery = ""
    private(set) var searchList: (any PaginatedListViewModel<Song>)?

    var currentList: any PaginatedListViewModel<Song> {
        searchList ?? recentList
    }

    private(set) var observableSelectedAlbumId: ObservedData<String>?
    private(set) var observableSelectedSong: ObservedData<Song>?

    // MARK: - Private State

    private var shouldRefreshRecent = true
    private var recentSongsUpdatedTask: Task<Void, Never>? // Haven't found a way to properly dispose of it :/

    // MARK: - Dependencies

    private let songService: SongSearchService
    private let container: any IoCContainer

    // MARK: - Lifecycle

    init(
        interactionService: InteractionService,
        songService: SongSearchService,
        container: any IoCContainer
    ) {
        self.container = container
        self.songService = songService
        recentList = container.recentSongsPaginatedListViewModel()

        let songPlayedEvent = interactionService.songMarkedPlayedEvent
        recentSongsUpdatedTask = Task { [weak self] in
            for await interaction in await songPlayedEvent.stream().stream {
                guard let self else { return }

                if recentList.items.first?.id != interaction.song.id {
                    shouldRefreshRecent = true
                }
            }
        }
    }

    // MARK: - Screen Events

    func onAppear() {
        guard searchList == nil else { return }
        prepareRecentList()
    }

    func handleSearchBar(focused: Bool) {
        if focused {
            guard searchList == nil else { return }
            withAnimation {
                searchList = container.paginatedListViewModel(ofKind: .dynamic(fetchSearch))
            }
        } else {
            guard searchList != nil else { return }
            withAnimation {
                searchList = nil
                workingSearchQuery = ""
                currentQuery = ""
            }
            prepareRecentList()
        }
    }

    func submitSearch() {
        let query = workingSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let isRetryingFailedSearch = if let searchList,
                                        query == currentQuery,
                                        case .error = searchList.loadState
        {
            true
        } else {
            false
        }
        guard !query.isEmpty,
              query != currentQuery || isRetryingFailedSearch,
              let searchList
        else { return }

        if isRetryingFailedSearch {
            searchList.interactWithError(shouldRetry: true)
            return
        }

        currentQuery = query
        Task {
            await searchList.refresh()
        }
    }

    // MARK: - Navigation

    func select(song: Song) {
        observableSelectedSong = .init(value: song)
    }

    func selectAlbum(of song: Song) {
        guard let albumId = song.album?.id else { return }
        observableSelectedAlbumId = .init(value: albumId)
    }

    // MARK: - Private Helpers

    private func prepareRecentList() {
        if shouldRefreshRecent {
            Task { await recentList.refresh() }
        } else {
            recentList.loadFirstPageIfNeeded()
        }
        shouldRefreshRecent = false
    }

    private func fetchSearch(
        page: Pagination<SongSearchParams>?
    ) async throws -> Pagination<SongSearchParams>.Page<Song> {
        try await songService.search(
            page ?? .first(params: .init(searchTerm: currentQuery), limit: ViewModelConstants.defaultSizePage)
        )
    }
}
