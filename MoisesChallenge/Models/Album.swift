//
//  Album.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

private let defaultTitleAlbum = String(localized: .commonUnknownTitle)

struct Album: Identifiable, Codable, Hashable, ArtistBearer, ArtworkBearer {
    let id: String
    let title: String?
    let artist: Artist?
    let itemArtwork: String?
    let mainArtwork: String?
    
    var displayTitle: String {
        title ?? defaultTitleAlbum
    }
    
    var songs: [Song]? // nil means the songs weren't loaded
}

protocol AlbumBearer {
    var album: Album? { get }
}

extension AlbumBearer {
    var displayAlbumTitle: String {
        album?.displayTitle ?? defaultTitleAlbum
    }
}
