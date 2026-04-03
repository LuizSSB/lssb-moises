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
    #Unique<SongInteractionSwiftData>([\.song.id])
    
    var id: String
    var song: Song
    var lastPlayedAt: Date
    
    init(song: Song, lastPlayedAt: Date = .now) {
        self.id = song.id
        self.song = song
        self.lastPlayedAt = lastPlayedAt
    }
}

extension SongInteraction {
    init(from data: SongInteractionSwiftData) {
        self = .init(song: data.song, lastPlayedAt: data.lastPlayedAt)
    }
}
