//
//  SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Combine

enum SongQueuePlaybackDirection {
    case previous,
         next
}

@MainActor
protocol SongPlayerQueue: AnyObject {
    typealias OnLoadedMoreArgument = (SongQueuePlaybackDirection?, Result<Void, Error>)
    
    var currentItem: Song? { get }
    var currentIndex: Int? { get }
    
    var onCurrentItemChanged: AnyPublisher<Song?, Never> { get }
    var onLoadedMore: AnyPublisher<OnLoadedMoreArgument, Never> { get } // nil direction means the loading was triggered by something other than the player.
    
    func isLoading(_ direction: SongQueuePlaybackDirection) -> Bool
    func has(_ direction: SongQueuePlaybackDirection) -> Bool
    func move(to direction: SongQueuePlaybackDirection)
}
