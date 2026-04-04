//
//  SongSearchService+Hybrid.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Foundation

extension SongSearchService {
    init(with cache: Cache) {
        self.init(
            search: { pagination in
                if let cached = try? await cache.service.search(pagination) {
                    return cached
                }
                
                let fresh = try await Self.iTunes.search(pagination)
                try? cache.add(page: fresh)
                return fresh
            }
        )
    }
    
    static let hybrid = Self(with: .init(container: swiftDataConfig.appModelContainer))
}
