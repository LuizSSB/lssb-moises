//
//  PaginatedListViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

protocol PaginatedListViewModel<Item>: ViewModel {
    associatedtype Item: Hashable & Sendable

    var items: [Item] { get }
    var loadState: PaginatedListLoadState { get }
    var hasMore: Bool { get }
    var lastLoadResult: Result<[Item], Error>? { get }

    func loadFirstPageIfNeeded()
    func loadNextPage()
    func refresh() async // Ideally, wouldn't need to be async, but view refreshing stuff requires it.
    func interactWithError(shouldRetry: Bool)
    func reset()
}
