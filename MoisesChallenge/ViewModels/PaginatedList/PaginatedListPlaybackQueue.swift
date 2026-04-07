//
//  PaginatedListPlaybackQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 04/04/26.
//

import Observation

@Observable
final class PaginatedListPlaybackQueue<Item: Identifiable & Equatable & Hashable & Sendable>: PlaybackQueue {
    // MARK: - Private State
    
    private var currentItemChangeCount = 0
    private var nextIndexBeingLoaded: Int?
    private let list: any PaginatedListViewModel<Item>
    
    // MARK: - Lifecycle
    
    init(list: any PaginatedListViewModel<Item>, selectedItem: Item) {
        self.list = list
        self.currentItem = selectedItem
    }
    
    // MARK: - PlaybackQueue Conformance
    
    private(set) var currentItem: Item? {
        didSet {
            currentItemChangeCount += 1
        }
    }
    
    var currentIndex: Int? {
        get {
            guard let currentItem else { return nil }
            return list.items.firstIndex(where: { $0.id == currentItem.id })
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
            
            return list.hasMore
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
            } else if list.hasMore {
                try await loadAndMoveToNext(at: nextIndex)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadAndMoveToNext(at index: Int) async throws {
        guard nextIndexBeingLoaded == nil else { return }

        let currentItemChangeCountBeforeLoading = currentItemChangeCount
        nextIndexBeingLoaded = index
        
        let nextLoadResultTask = Task { @MainActor [self] in
            await withCheckedContinuation { continuation in
                withObservationTracking {
                    _ = list.lastLoadResult
                } onChangeAsync: { [weak list] in
                    await continuation.resume(returning: list?.lastLoadResult)
                }
            }
        }
        
        list.loadNextPage()
        
        defer {
            nextIndexBeingLoaded = nil
        }
        
        switch await nextLoadResultTask.value {
        case .success:
            guard currentItemChangeCount == currentItemChangeCountBeforeLoading,
                  index < list.items.count
            else { return }
            
            currentItem = list.items[index]
        case .failure(let error):
            throw error
        case nil: break
        }
    }
}
