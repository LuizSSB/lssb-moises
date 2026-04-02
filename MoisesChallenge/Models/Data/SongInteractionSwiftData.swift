//
//  SongInteractionSwiftData.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

@Model
final class SongInteractionSwiftData {
    var song: Song
    var lastPlayedAt: Date
    
    init(song: Song, lastPlayedAt: Date = .now) {
        self.song = song
        self.lastPlayedAt = lastPlayedAt
    }
}

extension SongInteraction {
    var asSwiftData: SongInteractionSwiftData {
        .init(song: song, lastPlayedAt: lastPlayedAt)
    }
    
    init(from data: SongInteractionSwiftData) {
        self = .init(song: data.song, lastPlayedAt: data.lastPlayedAt)
    }
}
