//
//  AlbumSearchService+Hybrid.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//


import Foundation
import SwiftData

extension AlbumSearchService {
    init(with cache: Cache) {
        self.init(
            get: { albumId in
                if let cached = try? await cache.service.get(albumId) {
                    return cached
                }
                
                let fresh = try await Self.iTunes.get(albumId)
                try? cache.add(album: fresh)
                return fresh
            }
        )
    }
    
    static let hybrid = Self(with: .init(container: swiftDataConfig.appModelContainer))
}
