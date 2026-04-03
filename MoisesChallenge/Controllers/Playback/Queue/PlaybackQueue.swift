//
//  PlaybackQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

@MainActor
protocol PlaybackQueue<Item>: AnyObject {
    associatedtype Item: Sendable
    
    var currentItem: Item? { get }
    var currentIndex: Int? { get set }
    
    var currentItemChangedEvent: Event<Item?> { get }
    
    func isLoading(_ direction: PlaybackQueueDirection) -> Bool
    func has(_ direction: PlaybackQueueDirection) -> Bool
    func move(to direction: PlaybackQueueDirection) async throws
}
