//
//  ModelPresentation.swift
//  MoisesChallenge
//
//  Created by Codex on 03/04/26.
//

import Foundation

private let unknownTitle = String(localized: .commonUnknownTitle)
private let unknownArtist = String(localized: .commonUnknownArtist)

extension Song {
    var displayTitle: String {
        title ?? unknownTitle
    }

    var itemArtworkURL: URL? {
        URL(string: itemArtwork ?? "")
    }

    var mainArtworkURL: URL? {
        URL(string: mainArtwork ?? "")
    }

    var previewURL: URL? {
        URL(string: preview ?? "")
    }
}

extension Album {
    var displayTitle: String {
        title ?? unknownTitle
    }

    var displayArtistName: String {
        artist?.displayName ?? unknownArtist
    }

    var mainArtworkURL: URL? {
        URL(string: mainArtwork ?? "")
    }
}

extension Artist {
    var displayName: String {
        name ?? unknownArtist
    }
}

extension Song {
    var displayArtistName: String {
        artist?.displayName ?? unknownArtist
    }

    var displayAlbumTitle: String {
        album?.displayTitle ?? unknownTitle
    }
}
