//
//  AlbumViewModel+SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

extension AlbumViewModel {
    class SongPlayerQueue: MoisesChallenge.SongPlayerQueue {
        let songs: [Song]
        
        init?(songs: [Song], selectedSong: Song) {
            if !songs.isEmpty,
               !songs.contains(where: { $0.id == selectedSong.id }) {
                return nil
            }
            
            self.songs = songs
            self.currentItem = selectedSong
        }
        
        private(set) var currentItem: Song?
        
        var currentIndex: Int? {
            guard let currentItem else { return nil }
            return songs.firstIndex { $0.id == currentItem.id }
        }
        
        var hasPrevious: Bool {
            (currentIndex ?? 0) > 0
        }
        
        var hasNext: Bool {
            (currentIndex ?? .max) < songs.count - 1
        }
        
        var isLoadingNextForPlayer: Bool {
            false
        }
        
        func moveToPrevious() {
            guard let currentIndex else {
                currentItem = songs[0]
                return
            }
            
            if currentIndex == 0 {
                return
            }
            
            currentItem = songs[currentIndex - 1]
        }
        
        func moveToNext() {
            guard let currentIndex else {
                currentItem = songs[0]
                return
            }
            
            if currentIndex == songs.count - 1 {
                return
            }
            
            currentItem = songs[currentIndex + 1]
        }
    }
}
