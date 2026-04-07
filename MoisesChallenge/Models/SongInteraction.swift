//
//  SongInteraction.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation

struct SongInteraction: Equatable, Hashable, Codable {
    let song: Song
    let lastPlayedAt: Date
}
