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
    
    func songListViewModel() -> any SongListViewModel
    func songPlayerViewModel(queue: any PlaybackQueue<Song>) -> any SongPlayerViewModel
    func albumViewModel(albumId: String) -> any AlbumViewModel
    
    func presentationViewModel<T>() -> any PresentationViewModel<T>
    func paginatedListViewModel<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        fetch: @escaping @Sendable (Pagination<PaginationParams>?) async throws -> Pagination<PaginationParams>.Page<Item>
    ) -> any PaginatedListViewModel<Item, PaginationParams>
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
    
    func songListViewModel() -> any SongListViewModel {
        SongListViewModelImpl(
            interactionService: .swiftData,
            songService: .hybrid,
            container: self
        )
    }
    
    func songPlayerViewModel(queue: any PlaybackQueue<Song>) -> any SongPlayerViewModel {
        SongPlayerViewModelImpl(
            queue: queue,
            interactionService: .swiftData,
            container: self
        )
    }
    
    func albumViewModel(albumId: String) -> any AlbumViewModel {
        AlbumViewModelImpl(
            albumId: albumId,
            service: .hybrid,
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
}

final class LiveIoCContainer: IoCContainer {
}
