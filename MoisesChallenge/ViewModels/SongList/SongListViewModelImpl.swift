//
//  SongListViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Observation

private let defaultSizePage = 10

@Observable
final class SongListViewModelImpl: SongListViewModel {
    private(set) var recentList: any PaginatedListViewModel<Song, NullPaginationParams>
    
    var searchText = ""
    private(set) var currentQuery = ""
    private(set) var searchList: (any PaginatedListViewModel<Song, SongSearchParams>)?
    
    private(set) var player: any PresentationViewModel<any SongPlayerViewModel> = PresentationViewModelImpl()
    private(set) var album: any PresentationViewModel<AlbumViewModel> = PresentationViewModelImpl()

    private var shouldRefreshRecent = true
    private var recentSongsUpdatedTask: Task<Void, Never>?

    private let songService: SongSearchService

    init(interactionService: InteractionService, songService: SongSearchService) {
        self.songService = songService
        self.recentList = PaginatedListViewModelImpl(
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

    func onAppear() {
        guard searchList == nil else { return }
        prepareRecentList()
    }
    
    private func prepareRecentList() {
        if shouldRefreshRecent {
            Task { await recentList.refresh() }
        } else {
            recentList.loadFirstPageIfNeeded()
        }
        shouldRefreshRecent = false
    }

    func onSearchBar(focused: Bool) {
        if focused {
            guard searchList == nil else { return }
            searchList = PaginatedListViewModelImpl(fetch: fetchSearch)
        } else {
            guard searchList != nil else { return }
            searchList = nil
            searchText = ""
            currentQuery = ""
            prepareRecentList()
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
        let viewModel: any SongPlayerViewModel = SongPlayerViewModelImpl(
            queue: queue,
            interactionService: .swiftData
        )
        player.present(viewModel)
    }
    
    func onSelectAlbum(of song: Song) {
        guard let albumId = song.album?.id else { return }
        album.present(.init(albumId: albumId, service: .iTunes))
    }
    
    private func fetchSearch(
        page: Pagination<SongSearchParams>?
    ) async throws -> Pagination<SongSearchParams>.Page<Song> {
        try await songService.search(
            page
            ?? .first(
                params: .init(searchTerm: searchText),
                limit: defaultSizePage
            )
        )
    }
}
