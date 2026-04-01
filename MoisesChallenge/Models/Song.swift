//
//  Song.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Foundation

struct Song: Identifiable, Codable, Hashable, ArtistBearer, AlbumBearer, ArtworkBearer {
    let id: String
    var title: String?
    var artist: Artist?
    var album: Album?
    var itemArtwork: String?
    var mainArtwork: String?
    var durationSeconds: TimeInterval?
    var preview: String?
    
    var previewURL: URL? {
        .init(string: preview ?? "")
    }
    
    var displayTitle: String {
        title ?? "Unknown title"
    }
}
