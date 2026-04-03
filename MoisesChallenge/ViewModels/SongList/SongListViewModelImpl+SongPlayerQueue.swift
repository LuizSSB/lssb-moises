//
//  SongListViewModel+SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

extension SongListViewModelImpl {
    class SongPlayerQueue<PaginationParams: Hashable & Sendable>: MoisesChallenge.SongPlayerQueue {        
        private var nextIndexBeingLoaded: Int?
        private var pageLoadedHandlerTask: Task<Void, Never>?
        
        private let list: any PaginatedListViewModel<Song, PaginationParams>
        
        init(list: any PaginatedListViewModel<Song, PaginationParams>, selectedSong: Song) {
            self.list = list
            self.currentItem = selectedSong
        }
        
        private func preparePageLoadedHandler() {
            guard pageLoadedHandlerTask == nil else { return }
            
            let event = list.pageLoadedEvent
            pageLoadedHandlerTask = Task { [weak self] in
                for await _ in await event.stream().stream {
                    guard let self else { return }
                    
                    guard let nextIndexBeingLoaded = self.nextIndexBeingLoaded,
                          self.currentIndex == nextIndexBeingLoaded - 1
                    else { continue }
                    
                    self.nextIndexBeingLoaded = nil
                    if nextIndexBeingLoaded < self.list.items.count {
                        self.currentItem = self.list.items[nextIndexBeingLoaded]
                    }
                }
            }
        }
        
        deinit {
            pageLoadedHandlerTask?.cancel()
        }
        
        // MARK: - PlayerQueue conformance
        
        private(set) var currentItem: Song? {
            didSet {
                currentItemChangedEvent.emitAndForget(currentItem)
            }
        }
        
        var currentIndex: Int? {
            guard let currentItemId = currentItem?.id else { return nil }
            return list.items.firstIndex { $0.id == currentItemId }
        }
        
        var currentItemChangedEvent = Event<Song?>()
        
        var loadedMoreEvent = Event<OnLoadedMoreArgument>()
        
        func isLoading(_ direction: SongQueuePlaybackDirection) -> Bool {
            direction == .next && nextIndexBeingLoaded != nil && list.items.last == currentItem
        }
        
        func has(_ direction: SongQueuePlaybackDirection) -> Bool {
            switch direction {
            case .previous:
                guard let index = currentIndex else { return false }
                return index > 0
                
            case .next:
                guard let currentIndex else { return false }
                
                if currentIndex != list.items.count - 1 {
                    return true
                }
                
                return list.latestResult?.hasMore == true
            }
        }
        
        func move(to direction: SongQueuePlaybackDirection) {
            switch direction {
            case .previous:
                guard let currentIndex,
                      currentIndex > 0
                else { return }
                
                currentItem = list.items[currentIndex - 1]
                
            case .next:
                guard let currentIndex else { return }
                
                let nextIndex = currentIndex + 1
                if nextIndex < list.items.count {
                    currentItem = list.items[nextIndex]
                } else if list.latestResult?.hasMore == true {
                    preparePageLoadedHandler()
                    nextIndexBeingLoaded = nextIndex
                    list.loadNextPage()
                }
            }
        }
    }
}
