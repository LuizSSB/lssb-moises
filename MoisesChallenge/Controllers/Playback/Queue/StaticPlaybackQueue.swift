//
//  StaticPlaybackQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

class StaticPlaybackQueue<Item: Sendable & Equatable>: PlaybackQueue {
    let items: [Item]
    
    init?(items: [Item], selectedItem: Item) {
        if !items.isEmpty,
           !items.contains(where: { $0 == selectedItem }) {
            return nil
        }
        
        self.items = items
        self.currentItem = selectedItem
    }
    
    private(set) var currentItem: Item? {
        didSet {
            currentItemChangedEvent.emitAndForget(currentItem)
        }
    }
    
    var currentIndex: Int? {
        get {
            guard let currentItem else { return nil }
            return items.firstIndex { $0 == currentItem }
        }
        set {
            guard let newValue else {
                currentItem = nil
                return
            }
            
            guard newValue >= 0 && newValue < items.endIndex && newValue != currentIndex else { return }
            currentItem = items[newValue]
        }
    }
    
    let currentItemChangedEvent = Event<Item?>()
    
    var loadedMoreEvent = Event<OnLoadedMoreArgument>()
    
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool {
        false
    }
    
    func has(_ direction: PlaybackQueueDirection) -> Bool {
        switch direction {
        case .previous: return (currentIndex ?? 0) > 0
        case .next: return (currentIndex ?? .max) < items.count - 1
        }
    }
    
    func move(to direction: PlaybackQueueDirection) {
        switch direction {
        case .previous:
            guard let currentIndex else {
                currentItem = items[0]
                return
            }
            
            if currentIndex == 0 {
                return
            }
            
            currentItem = items[currentIndex - 1]
            
        case .next:
            guard let currentIndex else {
                currentItem = items[0]
                return
            }
            
            if currentIndex == items.count - 1 {
                return
            }
            
            currentItem = items[currentIndex + 1]
        }
    }
    
    func moveToFirst() {
        guard let firstItem = items.first else { return }
        currentItem = firstItem
    }
}
