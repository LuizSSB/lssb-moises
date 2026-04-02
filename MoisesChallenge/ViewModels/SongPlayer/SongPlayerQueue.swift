//
//  SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

enum SongQueuePlaybackDirection {
    case previous,
         next
}

@MainActor
protocol SongPlayerQueue: AnyObject {
    // nil direction means the loading was triggered by something other than the player.
    typealias OnLoadedMoreArgument = (SongQueuePlaybackDirection?, Result<Void, Error>)
    
    var currentItem: Song? { get }
    var currentIndex: Int? { get }
    
    var currentItemChangedEvent: Event<Song?> { get }
    var loadedMoreEvent: Event<OnLoadedMoreArgument> { get }
    
    func isLoading(_ direction: SongQueuePlaybackDirection) -> Bool
    func has(_ direction: SongQueuePlaybackDirection) -> Bool
    func move(to direction: SongQueuePlaybackDirection)
}
