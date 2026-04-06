//
//  CachedSongSearchSwiftData.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

@Model
final class CachedSongSearchPageSwiftData {
    #Unique<CachedSongSearchPageSwiftData>([\.searchTerm, \.offset, \.limit])
    
    var searchTerm: String
    var offset: Int
    var limit: Int?
    @Relationship(deleteRule: .cascade, inverse: \CachedSongSwiftData.searchPage)
    var entries: [CachedSongSwiftData]
    var cachedAt: Date
    
    init(searchTerm: String, offset: Int, limit: Int? = nil, entries: [Song], cachedAt: Date = .now) {
        self.searchTerm = searchTerm
        self.offset = offset
        self.limit = limit
        self.entries = entries.enumerated().map { index, song in
            CachedSongSwiftData(song: song, sortIndex: index)
        }
        self.cachedAt = cachedAt
    }
}

extension CachedSongSearchPageSwiftData {
    convenience init(from result: SongSearchPage) {
        self.init(
            searchTerm: result.pagination.params.searchTerm,
            offset: result.pagination.offset,
            limit: result.pagination.limit,
            entries: result.entries
        )
    }
}

extension SongSearchPage {
    init(from cached: CachedSongSearchPageSwiftData) {
        self.init(
            entries: cached.entries.sorted { $0.sortIndex < $1.sortIndex }.map(Song.init(from:)),
            pagination: .init(
                params: .init(searchTerm: cached.searchTerm),
                offset: cached.offset,
                limit: cached.limit
            )
        )
    }
}
