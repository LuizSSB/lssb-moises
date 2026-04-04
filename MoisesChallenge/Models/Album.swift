//
//  Album.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

struct Album: Identifiable, Codable, Hashable {
    let id: String
    let title: String?
    let artist: Artist?
    var itemArtwork: String?
    var mainArtwork: String?

    var songs: [Song]? // nil means the songs weren't loaded
}
