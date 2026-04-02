//
//  SongListViewModel+SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Combine

extension SongListViewModel {
    class SongPlayerQueue<PaginationParams: Hashable & Sendable>: MoisesChallenge.SongPlayerQueue {
        private let onCurrentItemChangedSubject = PassthroughSubject<Song?, Never>()
        private let onLoadedMoreSubject = PassthroughSubject<OnLoadedMoreArgument, Never>()
        
        private var nextIndexBeingLoaded: Int?
        private var cancellables = Set<AnyCancellable>()
        
        private let list: PaginatedListViewModel<Song, PaginationParams>
        
        init(list: PaginatedListViewModel<Song, PaginationParams>, selectedSong: Song) {
            self.list = list
            self.currentItem = selectedSong
        }
        
        // MARK: - PlayerQueue conformance
        
        private(set) var currentItem: Song? {
            didSet {
                onCurrentItemChangedSubject.send(currentItem)
            }
        }
        
        var currentIndex: Int? {
            guard let currentItemId = currentItem?.id else { return nil }
            return list.items.firstIndex { $0.id == currentItemId }
        }
        
        var onCurrentItemChanged: AnyPublisher<Song?, Never> {
            onCurrentItemChangedSubject.eraseToAnyPublisher()
        }
        
        var onLoadedMore: AnyPublisher<OnLoadedMoreArgument, Never> {
            onLoadedMoreSubject.eraseToAnyPublisher()
        }
        
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
                    if cancellables.isEmpty {
                        list.onPageLoadedPublisher.sink { [weak self] result in
                            guard let self,
                                  let nextIndexBeingLoaded = self.nextIndexBeingLoaded,
                                  self.currentIndex == nextIndexBeingLoaded - 1
                            else { return }
                            
                            self.nextIndexBeingLoaded = nil
                            self.currentItem = if nextIndexBeingLoaded < self.list.items.count {
                                self.list.items[nextIndexBeingLoaded]
                            } else {
                                nil
                            }
                        }
                        .store(in: &cancellables)
                    }
                    nextIndexBeingLoaded = nextIndex
                    list.loadNextPage()
                }
            }
        }
    }
}
