//
//  Song.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Foundation

struct Song: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let artist: String
    let title: String
    let itemArtwork: String
    let mainArtwork: String
    let durationSeconds: TimeInterval
    
    var itemArtworkURL: URL? {
        .init(string: itemArtwork)
    }
    
    var mainArtworkURL: URL? {
        .init(string: mainArtwork)
    }
}
