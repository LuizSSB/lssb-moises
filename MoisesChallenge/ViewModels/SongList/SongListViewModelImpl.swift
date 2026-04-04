//
//  SongListViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Observation
import SwiftUI

private let defaultSizePage = 10

@Observable
final class SongListViewModelImpl: SongListViewModel {
    // MARK: - Public State

    private(set) var recentList: any PaginatedListViewModel<Song, NullPaginationParams>
    var searchText = ""
    private(set) var currentQuery = ""
    private(set) var searchList: (any PaginatedListViewModel<Song, SongSearchParams>)?

    var currentList: any PaginatedListViewModel {
        searchList ?? recentList
    }

    private(set) var player: any PresentationViewModel<any SongPlayerViewModel>
    private(set) var album: any PresentationViewModel<any AlbumViewModel>

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
        self.player = container.presentationViewModel()
        self.album = container.presentationViewModel()
        self.recentList = container.paginatedListViewModel(
            fetch: {
                let page = try await interactionService.listPlayedSongs($0 ?? .first(limit: defaultSizePage))
                return .init(
                    entries: page.entries.map(\.song),
                    pagination: page.pagination
                )
            }
        )
        
        let songPlayedEvent = interactionService.songMarkedPlayedEvent
        recentSongsUpdatedTask = Task { [weak self] in
            for await interaction in await songPlayedEvent.stream().stream {
                guard let self else { return }
                
                if self.recentList.items.first == nil || self.recentList.items.first!.id != interaction.song.id {
                    self.shouldRefreshRecent = true
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
                searchList = container.paginatedListViewModel(fetch: fetchSearch)
            }
        } else {
            guard searchList != nil else { return }
            withAnimation {
                searchList = nil
                searchText = ""
                currentQuery = ""
            }
            prepareRecentList()
        }
    }

    func submitSearch() {
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

    // MARK: - Navigation

    func select(song: Song) {
        let queue: any MoisesChallenge.PlaybackQueue<Song> = if let searchList {
            PlaybackQueue(list: searchList, selectedSong: song)
        } else {
            PlaybackQueue(list: recentList, selectedSong: song)
        }
        let viewModel = container.songPlayerViewModel(queue: queue)
        player.present(viewModel)
    }
    
    func selectAlbum(of song: Song) {
        guard let albumId = song.album?.id else { return }
        let viewModel = container.albumViewModel(albumId: albumId)
        album.present(viewModel)
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
            page
            ?? .first(
                params: .init(searchTerm: currentQuery),
                limit: defaultSizePage
            )
        )
    }
}
