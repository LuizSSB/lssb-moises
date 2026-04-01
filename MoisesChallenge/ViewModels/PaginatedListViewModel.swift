//
//  PaginatedListLoadState.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Foundation
import Observation

enum PaginatedListLoadState: Equatable {
    case idle
    case loadingFirstPage
    case loadingNextPage
    case refreshing
    case loaded
    case empty
    case error(String)
}

@MainActor
@Observable
final class PaginatedListViewModel<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable> {
    typealias PageFetch = @Sendable (
        _ page: Pagination<PaginationParams>? // a `nil` page means the first one (or whatever one the client feels like.
    ) async throws -> Pagination<PaginationParams>.Page<Item>
    
    private(set) var items: [Item] = []
    private(set) var loadState: PaginatedListLoadState = .idle
    private(set) var latestResult: Pagination<PaginationParams>.Page<Item>?
    
    private var activeFetchTask: Task<Void, Never>?
    private let fetch: PageFetch

    init(fetch: @escaping PageFetch) {
        self.fetch = fetch
    }

    func loadFirstPageIfNeeded() {
        guard loadState == .idle else { return }
        load(mode: .firstPage)
    }

    func loadNextPage() {
        guard loadState == .loaded,
              let latestResult, latestResult.hasMore
        else { return }
        load(mode: .nextPage)
    }

    func refresh() {
        guard loadState != .refreshing else { return }
        load(mode: .refresh)
    }

    private enum LoadMode { case firstPage, nextPage, refresh }

    private func load(mode: LoadMode) {
        activeFetchTask?.cancel()

        let fetchConfig: (loadState: PaginatedListLoadState, pageToFetch: Pagination<PaginationParams>?)? = switch mode {
        case .firstPage:
            (.loadingFirstPage, nil)
        case .nextPage:
            if let latestResult {
                (.loadingNextPage, latestResult.hasMore ? latestResult.pagination.next :  nil)
            } else {
                nil
            }
        case .refresh:
            (.refreshing, nil)
        }
        guard let fetchConfig else { return }
        
        loadState = fetchConfig.loadState
        let currentFetch = fetch

        activeFetchTask = Task {
            do {
                let result = try await currentFetch(fetchConfig.pageToFetch)

                guard !Task.isCancelled else { return }

                switch mode {
                case .firstPage, .refresh:
                    items = result.entries
                case .nextPage:
                    items.append(contentsOf: result.entries)
                }
                
                latestResult = result
                loadState = items.isEmpty ? .empty : .loaded

            } catch is CancellationError {
                // Ignore cancelled task
            } catch {
                guard !Task.isCancelled else { return }
                loadState = .error(error.localizedDescription)
            }
        }
    }

    func reset() {
        items = []
        latestResult = nil
        loadState = .idle
    }
}
