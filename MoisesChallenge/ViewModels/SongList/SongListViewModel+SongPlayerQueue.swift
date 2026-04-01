//
//  SongListViewModel+SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Foundation

extension SongListViewModel {
    class SongListPlayerQueue<PaginationParams: Hashable & Sendable>: PlayerQueue {
        var selectedSongID: String?
        
        var selectedSong: Song? {
            get { currentItem }
            set { selectedSongID = newValue?.id }
        }
        
        var pendingAdvanceAfterLoad = false
        
        let list: PaginatedListViewModel<Song, PaginationParams>
        
        init(list: PaginatedListViewModel<Song, PaginationParams>) {
            self.list = list
        }
        
        // MARK: - PlayerQueue conformance
        
        var currentItem: Song? {
            guard let index = currentIndex else { return nil }
            return list.items[safe: index]
        }
        
        var currentIndex: Int? {
            guard let id = selectedSongID else { return nil }
            return list.items.firstIndex(where: { $0.id == id })
        }
        
        var hasPrevious: Bool {
            guard let index = currentIndex else { return false }
            return index > 0
        }
        
        var hasNext: Bool {
            guard let index = currentIndex else { return false }
            if index != list.items.count - 1 {
                return true
            }
            
            return list.latestResult?.hasMore == true
        }
        
        var isLoadingNextForPlayer: Bool {
            list.loadState == .loadingNextPage
        }
        
        func moveToPrevious() {
            guard let index = currentIndex,
                  index > 0
            else { return }
            
            selectedSongID = list.items[index - 1].id
        }
        
        func moveToNext() {
            guard let index = currentIndex else { return }
            
            let nextIndex = index + 1
            if nextIndex < list.items.count {
                selectedSongID = list.items[nextIndex].id
            } else if list.latestResult?.hasMore == true {
                list.loadNextPage()
                pendingAdvanceAfterLoad = true
            }
        }
        
        func select(songID: String) {
            selectedSongID = songID
        }
        
        // MARK: - Internal pagination advance
        
        func advanceIfPending() {
            guard pendingAdvanceAfterLoad,
                  let index = currentIndex,
                  index + 1 < list.items.count
            else { return }
            pendingAdvanceAfterLoad = false
            selectedSongID = list.items[index + 1].id
        }
    }
}
