//
//  AlbumSearchService+Hybrid.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

extension AlbumSearchService {
    init(cache: Cache, actual: Self) {
        self.init(
            get: { albumId in
                if let cached = try? await cache.service.get(albumId) {
                    return cached
                }

                let fresh = try await actual.get(albumId)
                try? cache.add(album: fresh)
                return fresh
            }
        )
    }

    static let hybrid = Self(
        cache: .init(container: swiftDataConfig.appModelContainer),
        actual: .iTunes
    )
}
