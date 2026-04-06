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
    #Unique<SongInteractionSwiftData>([\.id])
    
    var id: String
    @Relationship(deleteRule: .cascade, inverse: \CachedSongSwiftData.interaction)
    var storedSong: CachedSongSwiftData
    var lastPlayedAt: Date
    
    init(song: Song, lastPlayedAt: Date = .now) {
        self.id = song.id
        self.storedSong = CachedSongSwiftData(song: song)
        self.lastPlayedAt = lastPlayedAt
    }
}

extension SongInteraction {
    init(from data: SongInteractionSwiftData) {
        self = .init(
            song: .init(from: data.storedSong),
            lastPlayedAt: data.lastPlayedAt
        )
    }
}
