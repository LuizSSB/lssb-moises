//
//  AlbumSearchService+Hybrid.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//


import Foundation
import SwiftData

extension AlbumSearchService {
    static let hybrid = Self.init(
        get: { albumId in
            if let cached = try? await Self.cache.service.get(albumId) {
                return cached
            }
            
            let fresh = try await Self.iTunes.get(albumId)
            try? Self.cache.addToCache(fresh)
            return fresh
        }
    )
}
