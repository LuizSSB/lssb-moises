//
//  CachedAlbumSwiftData.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

@Model
class CachedAlbumSwiftData {
    #Unique<CachedAlbumSwiftData>([\.id])
    
    var id: String
    var title: String?
    var artist: Artist?
    var itemArtwork: String?
    var mainArtwork: String?
    var songs: [Song]
    var cachedAt: Date
    
    init(
        id: String,
        title: String? = nil,
        artist: Artist? = nil,
        itemArtwork: String? = nil,
        mainArtwork: String? = nil,
        songs: [Song],
        cachedAt: Date
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.itemArtwork = itemArtwork
        self.mainArtwork = mainArtwork
        self.songs = songs
        self.cachedAt = cachedAt
    }
}

extension CachedAlbumSwiftData {
    convenience init?(from album: Album, cachedAt: Date = .now) {
        guard let songs = album.songs else { return nil }
        
        self.init(
            id: album.id,
            title: album.title,
            artist: album.artist,
            itemArtwork: album.itemArtwork,
            mainArtwork: album.mainArtwork,
            songs: songs,
            cachedAt: cachedAt
        )
    }
}

extension Album {
    init(from album: CachedAlbumSwiftData) {
        self = .init(
            id: album.id,
            title: album.title,
            artist: album.artist,
            itemArtwork: album.itemArtwork,
            mainArtwork: album.mainArtwork,
            songs: album.songs
        )
    }
}
