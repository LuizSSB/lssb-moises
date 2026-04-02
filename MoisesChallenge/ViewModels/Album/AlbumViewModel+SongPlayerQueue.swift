//
//  AlbumViewModel+SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Combine

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
        
        private(set) var currentItem: Song? {
            didSet {
                onCurrentItemChangedSubject.send(currentItem)
            }
        }
        
        var currentIndex: Int? {
            guard let currentItem else { return nil }
            return songs.firstIndex { $0.id == currentItem.id }
        }
        
        let onCurrentItemChangedSubject = PassthroughSubject<Song?, Never>()
        
        var onCurrentItemChanged: AnyPublisher<Song?, Never> {
            onCurrentItemChangedSubject.eraseToAnyPublisher()
        }
        
        var onLoadedMore = Empty<OnLoadedMoreArgument, Never>().eraseToAnyPublisher()
        
        func isLoading(_ direction: SongQueuePlaybackDirection) -> Bool {
            false
        }
        
        func has(_ direction: SongQueuePlaybackDirection) -> Bool {
            switch direction {
            case .previous: return (currentIndex ?? 0) > 0
            case .next: return (currentIndex ?? .max) < songs.count - 1
            }
        }
        
        func move(to direction: SongQueuePlaybackDirection) {
            switch direction {
            case .previous:
                guard let currentIndex else {
                    currentItem = songs[0]
                    return
                }
                
                if currentIndex == 0 {
                    return
                }
                
                currentItem = songs[currentIndex - 1]
                
            case .next:
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
}
