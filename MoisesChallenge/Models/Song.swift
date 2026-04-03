//
//  Song.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Foundation

struct Song: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var title: String?
    var artist: Artist?
    var album: Album?
    var itemArtwork: String?
    var mainArtwork: String?
    var durationSeconds: TimeInterval?
    var preview: String?
}
