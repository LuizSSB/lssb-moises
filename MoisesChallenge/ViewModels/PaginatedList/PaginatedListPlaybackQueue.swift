//
//  PaginatedListPlaybackQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 04/04/26.
//


class PaginatedListPlaybackQueue<PaginationParams: Hashable & Sendable>: PlaybackQueue {
    // MARK: - Private State
    
    private var nextIndexBeingLoaded: Int?
    private let list: any PaginatedListViewModel<Song, PaginationParams>
    
    // MARK: - Lifecycle
    
    init(list: any PaginatedListViewModel<Song, PaginationParams>, selectedSong: Song) {
        self.list = list
        self.currentItem = selectedSong
    }
    
    // MARK: - PlaybackQueue Conformance
    
    private(set) var currentItem: Song? {
        didSet {
            currentItemChangedEvent.emitAndForget(currentItem)
        }
    }
    
    var currentIndex: Int? {
        get {
            guard let currentItemId = currentItem?.id else { return nil }
            return list.items.firstIndex { $0.id == currentItemId }
        }
        set {
            guard let newValue else {
                currentItem = nil
                return
            }
            
            guard newValue >= 0 && newValue < list.items.endIndex && newValue != currentIndex else { return }
            currentItem = list.items[newValue]
        }
    }
    
    var currentItemChangedEvent = Event<Song?>()
    
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool {
        direction == .next && nextIndexBeingLoaded != nil && list.items.last == currentItem
    }
    
    func has(_ direction: PlaybackQueueDirection) -> Bool {
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
    
    func move(to direction: PlaybackQueueDirection) async throws {
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
                try await loadAndMoveToNext(at: nextIndex)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadAndMoveToNext(at index: Int) async throws {
        guard nextIndexBeingLoaded == nil else { return }
        
        let streamData = await list.pageLoadedEvent.stream()
        nextIndexBeingLoaded = index
        list.loadNextPage()
        
        defer {
            nextIndexBeingLoaded = nil
        }
        
        var iterator = streamData.stream.makeAsyncIterator()
        guard let result = await iterator.next() else { return }
        
        switch result {
        case .success:
            guard index < list.items.count else { return }
            currentItem = list.items[index]
        case .failure(let error):
            throw error
        }
    }
    }
