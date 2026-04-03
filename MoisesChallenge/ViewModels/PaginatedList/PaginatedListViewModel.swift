//
//  PaginatedListViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

@MainActor
protocol PaginatedListViewModel<Item, PaginationParams>: AnyObject, Sendable {
    associatedtype Item: Hashable & Sendable
    associatedtype PaginationParams: Hashable & Sendable
    
    var items: [Item] { get }
    var loadState: PaginatedListLoadState { get }
    var latestResult: Pagination<PaginationParams>.Page<Item>? { get }
    var pageLoadedEvent: Event<Result<Pagination<PaginationParams>.Page<Item>, Error>> { get }
    
    func loadFirstPageIfNeeded()
    func loadNextPage()
    func refresh() async // Ideally, wouldn't need to be async, but view refreshing stuff requires it.
    func onInteractionWithError(shouldRetry: Bool)
    func reset()
}

extension PaginatedListViewModel {
    var hasMore: Bool {
        latestResult?.hasMore ?? false
    }
}
