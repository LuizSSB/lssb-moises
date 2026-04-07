//
//  IoCContainer.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

protocol IoCContainer: AnyObject, Sendable {
    // Services

    func interactionService() -> InteractionService
    func songSearchService() -> SongSearchService
    func albumSearchService() -> AlbumSearchService

    // Main view models

    @MainActor
    func appViewModel() -> any AppViewModel

    @MainActor
    func songListViewModel() -> any SongListViewModel

    @MainActor
    func completeSongPlayerViewModel(
        songList: any PaginatedListViewModel<Song>,
        selectedSong: Song
    ) -> any CompleteSongPlayerViewModel

    @MainActor
    func albumViewModel(albumId: String) -> any AlbumViewModel

    // Utility view models

    @MainActor
    func focusedSongPlayerViewModel(queue: any PlaybackQueue<Song>) -> any FocusedSongPlayerViewModel

    @MainActor
    func paginatedListViewModel<Item: Hashable & Sendable>(
        ofKind kind: PaginatedListViewModelDependencyKind<Item, some Hashable & Sendable>
    ) -> any PaginatedListViewModel<Item>

    // Controllers

    @MainActor
    func songPlaybackController() -> any SongPlaybackController

    @MainActor
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

    @MainActor
    func appViewModel() -> any AppViewModel {
        AppViewModelImpl(container: self)
    }

    @MainActor
    func songListViewModel() -> any SongListViewModel {
        SongListViewModelImpl(
            interactionService: interactionService(),
            songService: songSearchService(),
            container: self
        )
    }

    @MainActor
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

    @MainActor
    func focusedSongPlayerViewModel(queue: any PlaybackQueue<Song>) -> any FocusedSongPlayerViewModel {
        FocusedSongPlayerViewModelImpl(
            queue: queue,
            playbackController: songPlaybackController(),
            interactionService: interactionService()
        )
    }

    @MainActor
    func albumViewModel(albumId: String) -> any AlbumViewModel {
        AlbumViewModelImpl(
            albumId: albumId,
            service: albumSearchService(),
            container: self
        )
    }

    @MainActor
    func paginatedListViewModel<Item: Hashable & Sendable>(
        ofKind kind: PaginatedListViewModelDependencyKind<Item, some Hashable & Sendable>
    ) -> any PaginatedListViewModel<Item> {
        switch kind {
        case let .static(items):
            PaginatedListViewModelImpl(staticItems: items)
        case let .dynamic(fetch, initialPage):
            PaginatedListViewModelImpl(fetch: fetch, initialPage: initialPage)
        }
    }

    @MainActor
    func songPlaybackController() -> any SongPlaybackController {
        AVSongPlaybackController()
    }

    @MainActor
    func playbackQueue<Item: Identifiable & Equatable & Hashable & Sendable>(
        ofKind kind: PlaybackQueueDependencyKind<Item>,
        selectedItem: Item
    ) -> any PlaybackQueue<Item> {
        switch kind {
        case let .static(items):
            StaticPlaybackQueue(items: items, selectedItem: selectedItem)
        case let .paginated(list):
            PaginatedListPlaybackQueue(list: list, selectedItem: selectedItem)
        }
    }
}

final class LiveIoCContainer: IoCContainer {}
