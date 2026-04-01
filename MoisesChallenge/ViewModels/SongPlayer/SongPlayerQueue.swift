//
//  SongPlayerQueue.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

@MainActor
protocol SongPlayerQueue: AnyObject {
    var currentItem: Song? { get }
    var currentIndex: Int? { get }
    var hasPrevious: Bool { get }
    var hasNext: Bool { get }
    var isLoadingNextForPlayer: Bool { get }
    func moveToPrevious()
    func moveToNext()
}
