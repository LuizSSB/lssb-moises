//
//  IoCContainer.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

@MainActor
protocol IoCContainer: AnyObject {
    func interactionService() -> InteractionService
    func songSearchService() -> SongSearchService
    func albumSearchService() -> AlbumSearchService
    func songPlaybackController() -> any SongPlaybackController
    
    func songListViewModel() -> any SongListViewModel
    func songPlayerViewModel(queue: any PlaybackQueue<Song>) -> any SongPlayerViewModel
    func albumViewModel(albumId: String) -> any AlbumViewModel
    
    func presentationViewModel<T>() -> any PresentationViewModel<T>
    func paginatedListViewModel<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        fetch: @escaping @Sendable (Pagination<PaginationParams>?) async throws -> Pagination<PaginationParams>.Page<Item>
    ) -> any PaginatedListViewModel<Item, PaginationParams>
    func playbackQueue<Item: Equatable & Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        ofKind kind: PlaybackQueueDependencyKind<Item, PaginationParams>,
        selectedItem: Item
    ) -> (any PlaybackQueue<Item>)?
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

    func songPlaybackController() -> any SongPlaybackController {
        AVSongPlaybackController()
    }
    
    func songListViewModel() -> any SongListViewModel {
        SongListViewModelImpl(
            interactionService: interactionService(),
            songService: songSearchService(),
            container: self
        )
    }
    
    func songPlayerViewModel(queue: any PlaybackQueue<Song>) -> any SongPlayerViewModel {
        SongPlayerViewModelImpl(
            queue: queue,
            playbackController: songPlaybackController(),
            interactionService: interactionService(),
            container: self
        )
    }
    
    func albumViewModel(albumId: String) -> any AlbumViewModel {
        AlbumViewModelImpl(
            albumId: albumId,
            service: albumSearchService(),
            container: self
        )
    }
    
    func presentationViewModel<T>() -> any PresentationViewModel<T> {
        PresentationViewModelImpl<T>()
    }
    
    func paginatedListViewModel<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        fetch: @escaping @Sendable (Pagination<PaginationParams>?) async throws -> Pagination<PaginationParams>.Page<Item>
    ) -> any PaginatedListViewModel<Item, PaginationParams> {
        PaginatedListViewModelImpl(fetch: fetch)
    }
    
    func playbackQueue<Item: Equatable & Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        ofKind kind: PlaybackQueueDependencyKind<Item, PaginationParams>,
        selectedItem: Item
    ) -> (any PlaybackQueue<Item>)? {
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
