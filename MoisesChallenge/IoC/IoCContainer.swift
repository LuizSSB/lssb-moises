//
//  IoCContainer.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

@MainActor
protocol IoCContainer: AnyObject, Sendable {
    // Services
    func interactionService() -> InteractionService
    func songSearchService() -> SongSearchService
    func albumSearchService() -> AlbumSearchService
    
    // Main view models
    func appViewModel() -> any AppViewModel
    func songListViewModel() -> any SongListViewModel
    func completeSongPlayerViewModel(
        songList: any PaginatedListViewModel<Song>,
        selectedSong: Song
    ) -> any CompleteSongPlayerViewModel
    func albumViewModel(albumId: String) -> any AlbumViewModel
    
    // Utility view models
    func focusedSongPlayerViewModel(queue: any PlaybackQueue<Song>) -> any FocusedSongPlayerViewModel
    func paginatedListViewModel<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        ofKind kind: PaginatedListViewModelDependencyKind<Item, PaginationParams>
    ) -> any PaginatedListViewModel<Item>
    
    // Controllers
    func songPlaybackController() -> any SongPlaybackController
    func playbackQueue<Item: Identifiable & Equatable & Hashable & Sendable>(
        ofKind kind: PlaybackQueueDependencyKind<Item>,
        selectedItem: Item
    ) -> any PlaybackQueue<Item>
}

extension IoCContainer {
    func interactionService() -> InteractionService {
        .swiftData
    }
    
    func songSearchService() -> SongSearchService {
        .hybrid
    }
    
    func albumSearchService() -> AlbumSearchService {
        .hybrid
    }
    
    func appViewModel() -> any AppViewModel {
        AppViewModelImpl(container: self)
    }
    
    func songListViewModel() -> any SongListViewModel {
        SongListViewModelImpl(
            interactionService: interactionService(),
            songService: songSearchService(),
            container: self
        )
    }
    
    func completeSongPlayerViewModel(
        songList: any PaginatedListViewModel<Song>,
        selectedSong: Song
    ) -> any CompleteSongPlayerViewModel {
        CompleteSongPlayerViewModelImpl(
            songList: songList,
            selectedSong: selectedSong,
            container: self
        )
    }
    
    func focusedSongPlayerViewModel(queue: any PlaybackQueue<Song>) -> any FocusedSongPlayerViewModel {
        FocusedSongPlayerViewModelImpl(
            queue: queue,
            playbackController: songPlaybackController(),
            interactionService: interactionService()
        )
    }
    
    func albumViewModel(albumId: String) -> any AlbumViewModel {
        AlbumViewModelImpl(
            albumId: albumId,
            service: albumSearchService(),
            container: self
        )
    }
    
    func paginatedListViewModel<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        ofKind kind: PaginatedListViewModelDependencyKind<Item, PaginationParams>
    ) -> any PaginatedListViewModel<Item> {
        switch kind {
        case let .static(items):
            return PaginatedListViewModelImpl(staticItems: items)
        case let .dynamic(fetch, initialPage):
            return PaginatedListViewModelImpl(fetch: fetch, initialPage: initialPage)
        }
    }
    
    func songPlaybackController() -> any SongPlaybackController {
        AVSongPlaybackController()
    }
    
    func playbackQueue<Item: Identifiable & Equatable & Hashable & Sendable>(
        ofKind kind: PlaybackQueueDependencyKind<Item>,
        selectedItem: Item
    ) -> any PlaybackQueue<Item> {
        switch kind {
        case let .static(items):
            return StaticPlaybackQueue(items: items, selectedItem: selectedItem)
        case let .paginated(list):
            return PaginatedListPlaybackQueue(list: list, selectedItem: selectedItem)
        }
    }
}

final class LiveIoCContainer: IoCContainer {
}
