//
//  CachedSongSearchSwiftData.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

@Model
final class CachedSongSearchSwiftData {
    var query: String
    var index: Int
    var song: Song
    var createdAt: Date
    
    init(query: String, index: Int, song: Song, createdAt: Date) {
        self.query = query
        self.index = index
        self.song = song
        self.createdAt = createdAt
    }
}
