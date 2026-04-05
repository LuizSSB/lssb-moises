//
//  CachedSongSwiftData.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 04/04/26.
//


import Foundation
import SwiftData

@Model
final class CachedSongSwiftData {
    var id: String
    var sortIndex: Int
    var title: String?
    var artistId: String?
    var artistName: String?
    var albumId: String?
    var albumTitle: String?
    var albumArtistId: String?
    var albumArtistName: String?
    var albumItemArtwork: String?
    var albumMainArtwork: String?
    var itemArtwork: String?
    var mainArtwork: String?
    var durationSeconds: Double?
    var preview: String?
    
    init(song: Song, sortIndex: Int = 0) {
        id = song.id
        self.sortIndex = sortIndex
        title = song.title
        artistId = song.artist?.id
        artistName = song.artist?.name
        albumId = song.album?.id
        albumTitle = song.album?.title
        albumArtistId = song.album?.artist?.id
        albumArtistName = song.album?.artist?.name
        albumItemArtwork = song.album?.itemArtwork
        albumMainArtwork = song.album?.mainArtwork
        itemArtwork = song.itemArtwork
        mainArtwork = song.mainArtwork
        durationSeconds = song.durationSeconds
        preview = song.preview
    }
}

extension Song {
    init(from cached: CachedSongSwiftData) {
        self = Song(
            id: cached.id,
            title: cached.title,
            artist: cached.artistId.map {
                Artist(id: $0, name: cached.artistName)
            },
            album: cached.albumId.map {
                Album(
                    id: $0,
                    title: cached.albumTitle,
                    artist: cached.albumArtistId.map {
                        Artist(id: $0, name: cached.albumArtistName)
                    }
                )
            },
            itemArtwork: cached.itemArtwork,
            mainArtwork: cached.mainArtwork,
            durationSeconds: cached.durationSeconds,
            preview: cached.preview
        )
    }
}
