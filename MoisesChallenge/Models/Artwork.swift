//
//  Artwork.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Foundation

protocol ArtworkBearer {
    var itemArtwork: String? { get }
    var mainArtwork: String? { get }
}

extension ArtworkBearer {
    var itemArtworkURL: URL? {
        .init(string: itemArtwork ?? "")
    }
    
    var mainArtworkURL: URL? {
        .init(string: mainArtwork ?? "")
    }
}
