//
//  Artist.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

private let defaultArtistName = String(localized: .commonUnknownArtist)

struct Artist: Codable, Hashable {
    let id: String
    var name: String?
    
    var displayName: String {
        name ?? defaultArtistName
    }
}

protocol ArtistBearer {
    var artist: Artist? { get }
}

extension ArtistBearer {
    var displayArtistName: String {
        artist?.displayName ?? defaultArtistName
    }
}
