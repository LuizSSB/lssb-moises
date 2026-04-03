//
//  PlaybackQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

@MainActor
protocol PlaybackQueue<Item>: AnyObject {
    associatedtype Item: Sendable
    
    typealias OnLoadedMoreArgument = (songBatchStartIndex: Int, Result<Void, Error>)
    
    var currentItem: Item? { get }
    var currentIndex: Int? { get set }
    
    var currentItemChangedEvent: Event<Item?> { get }
    var loadedMoreEvent: Event<OnLoadedMoreArgument> { get }
    
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool
    func has(_ direction: PlaybackQueueDirection) -> Bool
    func move(to direction: PlaybackQueueDirection)
}
