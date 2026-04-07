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
    var artistId: String?
    var artistName: String?
    var itemArtwork: String?
    var mainArtwork: String?
    @Relationship(deleteRule: .cascade, inverse: \CachedSongSwiftData.album)
    var songs: [CachedSongSwiftData]
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
        artistId = artist?.id
        artistName = artist?.name
        self.itemArtwork = itemArtwork
        self.mainArtwork = mainArtwork
        self.songs = songs.enumerated().map { index, song in
            CachedSongSwiftData(song: song, sortIndex: index)
        }
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
            artist: {
                guard let artistId = album.artistId else { return nil }
                return Artist(id: artistId, name: album.artistName)
            }(),
            itemArtwork: album.itemArtwork,
            mainArtwork: album.mainArtwork,
            songs: album.songs.sorted { $0.sortIndex < $1.sortIndex }.map(Song.init(from:))
        )
    }
}
