//
//  SongSearchService+Hybrid.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Foundation

extension SongSearchService {
    init(cache: Cache, actual: Self) {
        self.init(
            search: { pagination in
                if let cached = try? await cache.service.search(pagination) {
                    return cached
                }
                
                let fresh = try await actual.search(pagination)
                try? cache.add(page: fresh)
                return fresh
            }
        )
    }
    
    static let hybrid = Self(
        cache: .init(container: swiftDataConfig.appModelContainer),
        actual: .iTunes
    )
}
