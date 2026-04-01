//
//  Song.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Foundation

struct Song: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let artist: String?
    let title: String?
    let itemArtwork: String?
    let mainArtwork: String?
    let durationSeconds: TimeInterval?
    let preview: String?
    
    var itemArtworkURL: URL? {
        .init(string: itemArtwork ?? "")
    }
    
    var mainArtworkURL: URL? {
        .init(string: mainArtwork ?? "")
    }
    
    var previewURL: URL? {
        .init(string: preview ?? "")
    }
    
    var displayTitle: String {
        title ?? "Unknown title"
    }
    
    var displayArtist: String {
        artist ?? "Unknown artist"
    }
}
