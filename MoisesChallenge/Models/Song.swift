//
//  Song.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

struct Song: Codable, Hashable {
    let id: String
    let artist: String
    let name: String
    let itemArtwork: String
    let mainArtwork: String
    let durationSeconds: Int
}
