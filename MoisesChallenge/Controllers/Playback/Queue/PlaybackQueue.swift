//
//  PlaybackQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Observation

@MainActor
protocol PlaybackQueue<Item>: AnyObject, Sendable, Observable {
    associatedtype Item: Sendable

    var currentItem: Item? { get }
    var currentIndex: Int? { get set }

    func isLoading(_ direction: PlaybackQueueDirection) -> Bool
    func has(_ direction: PlaybackQueueDirection) -> Bool
    func move(to direction: PlaybackQueueDirection) async throws
}
