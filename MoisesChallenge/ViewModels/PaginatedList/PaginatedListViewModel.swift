//
//  PaginatedListViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

@MainActor
protocol BasePaginatedListViewModel<Item>: AnyObject, Sendable {
    associatedtype Item: Hashable & Sendable
    
    var items: [Item] { get }
    var loadState: PaginatedListLoadState { get }
    var hasMore: Bool { get }
    
    func loadFirstPageIfNeeded()
    func loadNextPage()
    func refresh() async // Ideally, wouldn't need to be async, but view refreshing stuff requires it.
    func interactWithError(shouldRetry: Bool)
    func reset()
}

protocol PaginatedListViewModel<Item, PaginationParams>: BasePaginatedListViewModel {
    associatedtype PaginationParams: Hashable & Sendable
    
    var latestResult: Pagination<PaginationParams>.Page<Item>? { get }
    var pageLoadedEvent: Event<Result<Pagination<PaginationParams>.Page<Item>, Error>> { get }
}

extension PaginatedListViewModel {
    var hasMore: Bool {
        latestResult?.hasMore ?? false
    }
}
