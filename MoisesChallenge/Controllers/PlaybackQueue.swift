//
//  PlaybackQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

@MainActor
protocol PlaybackQueue<Item>: AnyObject {
    associatedtype Item: Sendable
    
    // nil direction means the loading was triggered by something other than the player.
    typealias OnLoadedMoreArgument = (PlaybackQueueDirection?, Result<Void, Error>)
    
    var currentItem: Item? { get }
    var currentIndex: Int? { get }
    
    var currentItemChangedEvent: Event<Item?> { get }
    var loadedMoreEvent: Event<OnLoadedMoreArgument> { get }
    
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool
    func has(_ direction: PlaybackQueueDirection) -> Bool
    func move(to direction: PlaybackQueueDirection)
}
