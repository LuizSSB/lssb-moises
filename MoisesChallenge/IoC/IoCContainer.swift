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
    func paginatedListPlaybackQueue<Item: Equatable & Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        list: any PaginatedListViewModel<Item, PaginationParams>, selectedItem: Item
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
    
    func paginatedListPlaybackQueue<Item: Equatable & Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        list: any PaginatedListViewModel<Item, PaginationParams>, selectedItem: Item
    ) -> any PlaybackQueue<Item> {
        PaginatedListPlaybackQueue(list: list, selectedItem: selectedItem)
    }
}

final class LiveIoCContainer: IoCContainer {
}
