//
//  SongListViewModel+SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Foundation

extension SongListViewModel {
    class SongPlayerQueue<PaginationParams: Hashable & Sendable>: MoisesChallenge.SongPlayerQueue {
        var selectedSongID: String?
        
        var selectedSong: Song? {
            get { currentItem }
            set { selectedSongID = newValue?.id }
        }
        
        var pendingAdvanceAfterLoad = false
        
        let list: PaginatedListViewModel<Song, PaginationParams>
        
        init(list: PaginatedListViewModel<Song, PaginationParams>, selectedSong: Song) {
            self.list = list
            self.selectedSong = selectedSong
        }
        
        // MARK: - PlayerQueue conformance
        
        var currentItem: Song? {
            guard let currentIndex else { return nil }
            return list.items[safe: currentIndex]
        }
        
        var currentIndex: Int? {
            guard let selectedSongID else { return nil }
            return list.items.firstIndex(where: { $0.id == selectedSongID })
        }
        
        var hasPrevious: Bool {
            guard let index = currentIndex else { return false }
            return index > 0
        }
        
        var hasNext: Bool {
            guard let currentIndex else { return false }
            if currentIndex != list.items.count - 1 {
                return true
            }
            
            return list.latestResult?.hasMore == true
        }
        
        var isLoadingNextForPlayer: Bool {
            list.loadState == .loadingNextPage
        }
        
        func moveToPrevious() {
            guard let currentIndex,
                  currentIndex > 0
            else { return }
            
            selectedSongID = list.items[currentIndex - 1].id
        }
        
        func moveToNext() {
            guard let currentIndex else { return }
            
            let nextIndex = currentIndex + 1
            if nextIndex < list.items.count {
                selectedSongID = list.items[nextIndex].id
            } else if list.latestResult?.hasMore == true {
                list.loadNextPage()
                pendingAdvanceAfterLoad = true
            }
        }
        
        // MARK: - Internal pagination advance
        
        func advanceIfPending() {
            guard pendingAdvanceAfterLoad,
                  let currentIndex,
                  currentIndex + 1 < list.items.count
            else { return }
            pendingAdvanceAfterLoad = false
            selectedSongID = list.items[currentIndex + 1].id
        }
    }
}
