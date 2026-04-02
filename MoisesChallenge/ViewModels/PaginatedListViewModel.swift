//
//  PaginatedListLoadState.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI
import Combine

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
    typealias PageResult = Pagination<PaginationParams>.Page<Item>
    
    typealias PageFetch = @Sendable (
        _ page: Pagination<PaginationParams>? // a `nil` page means the first one (or whatever one the client feels like.
    ) async throws -> Pagination<PaginationParams>.Page<Item>
    
    private(set) var items: [Item] = []
    private(set) var loadState: PaginatedListLoadState = .idle
    private(set) var latestResult: PageResult?
    
    private let onPageLoadedSubject = PassthroughSubject<Result<PageResult, Error>, Never>()
    var onPageLoadedPublisher: AnyPublisher<Result<PageResult, Error>, Never> {
        onPageLoadedSubject.eraseToAnyPublisher()
    }
    
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

    // Ideally, wouldn't need to be async, but view refreshing stuff requires it.
    func refresh() async {
        guard loadState != .refreshing else { return }
        let didAlreadyHaveStuff = latestResult != nil
        
        load(mode: .refresh)
        
        // HACK: after refreshing, if nothing has changed, the top items won't be rerendered, and, as such, their onAppear will not be triggered, so if all of the page's results fit into the list, it won't load more by itself.
        if case .success = await activeFetchTask?.result,
           didAlreadyHaveStuff {
           loadNextPage()
        }
    }

    private enum LoadMode { case firstPage, nextPage, refresh }

    private func load(mode: LoadMode) {
        activeFetchTask?.cancel()

        activeFetchTask = Task {
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
            
            withAnimation {
                loadState = fetchConfig.loadState
            }
            
            let currentFetch = fetch
            
            do {
                let result = try await currentFetch(fetchConfig.pageToFetch)

                guard !Task.isCancelled else { return }
                
                withAnimation {
                    switch mode {
                    case .firstPage, .refresh:
                        items = result.entries
                    case .nextPage:
                        items.append(contentsOf: result.entries)
                    }
                    
                    latestResult = result
                    loadState = items.isEmpty ? .empty : .loaded
                    
                    onPageLoadedSubject.send(.success(result))
                }

            } catch is CancellationError {
                // Ignore cancelled task
            } catch {
                guard !Task.isCancelled else { return }
                
                withAnimation {
                    loadState = .error(error.localizedDescription)
                    
                    onPageLoadedSubject.send(.failure(error))
                }
            }
        }
    }

    func reset() {
        items = []
        latestResult = nil
        loadState = .idle
    }
}
