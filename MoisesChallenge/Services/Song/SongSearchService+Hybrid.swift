//
//  SongSearchService+Hybrid.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Foundation

extension SongSearchService {
    static let hybrid = Self(
        search: { pagination in
            if let cached = try? await Self.cache.service.search(pagination) {
                return cached
            }
            
            let fresh = try await Self.iTunes.search(pagination)
            try? Self.cache.addToCache(fresh)
            return fresh
        }
    )
}
