//
//  SongListViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI
import FactoryKit

private let defaultSearchLimit = 10

@Observable class SongListViewModel: ViewModel {
    struct State: ViewModelState {
        var currentSearchTerm: String?
        var workingSearchTerm = ""
        
        var songs: [Song]?
        var songsFetchStatus: ActionStatus<SongDataSource.PaginationResult, String> = .none
        
        var canLoadMore: Bool {
            guard case let .success(result) = songsFetchStatus,
                  !result.reachedEnd
            else { return true }
            
            return false
        }
        
        var isLoadingFirstBatch: Bool {
            if case .running = songsFetchStatus,
               songs == nil {
                return true
            }
            return false
        }
        
        var isLoadingMore: Bool {
            if case .running = songsFetchStatus,
               let songs, !songs.isEmpty {
                return true
            }
            return false
        }
    }
    
    private(set) var state = State()
    
    @ObservationIgnored
    @Injected(\.songDataSource) private var songDataSource
    
    // Ideally, this wouldn't need to be async, but view refreshing view layer requires it.
    func refresh(force: Bool = false) async {
        guard let searchTerm = state.currentSearchTerm else {
            state.songs = nil
            state.songsFetchStatus = .none
            // TODO: load recently played songs
            return
        }
        
        guard let result = await load(
            pagination: .first(params: .init(searchTerm: searchTerm), limit: defaultSearchLimit),
            force: force
        ) else { return }
        
        update {
            let didAlreadyHaveStuff = self.state.songs != nil
            self.state.songs = result.entries
            
            // HACK: after refreshing, if nothing has changed, the top items won't be rerendered, and, as such, their onAppear will not be triggered, so if all of the page's results fit into the list, it won't loadMore by itself.
            if didAlreadyHaveStuff {
                self.loadMore()
            }
        }
    }
    
    func loadMore() {
        guard case let .success(result) = state.songsFetchStatus,
              !result.reachedEnd
        else { return }
        
        Task {
            guard let result = await load(pagination: result.pagination.next, force: false) else { return }
            
            self.update {
                self.state.songs = (self.state.songs ?? []) + result.entries
            }
        }
    }
    
    private func load(pagination: SongDataSource.Pagination, force: Bool) async -> SongDataSource.PaginationResult? {
        guard state.songsFetchStatus != .running else { return nil }
        
        state.songsFetchStatus = .running
        do {
            let page = try await songDataSource.list(pagination)
            
            guard force || pagination.params.searchTerm == state.currentSearchTerm else { return nil }
            state.songsFetchStatus = .success(page)
            return page
        } catch {
            state.songsFetchStatus = .failure("Couldn't load entries.")
            return nil
        }
    }
    
    func abandonLoading() {
        state.songsFetchStatus = .none
    }
    
    func updateWorkingSearchTerm(to text: String) {
        state.workingSearchTerm = text
    }
    
    func search() {
        state.currentSearchTerm = state.workingSearchTerm
        Task {
            await self.refresh(force: true)
        }
    }
    
    func select(_ song: Song) {
        // TODO
    }
}

extension Container {
    var songListViewModel: Factory<SongListViewModel> {
        self { @MainActor in SongListViewModel() }
    }
}
