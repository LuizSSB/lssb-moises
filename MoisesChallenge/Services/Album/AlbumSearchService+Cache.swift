//
//  AlbumSearchService+Cache.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

extension AlbumSearchService {
    static let cache = (
        addToCache: { @Sendable (album: Album) in
            guard let cached = CachedAlbumSwiftData(from: album) else { return }
            
            let context = ModelContext(swiftDataConfig.appModelContainer)
            context.insert(cached)
            try context.save()
        },
        service: Self.init(
            get: { albumId in
                let context = ModelContext(swiftDataConfig.appModelContainer)
                var descriptor = FetchDescriptor<CachedAlbumSwiftData>(
                    predicate: #Predicate { $0.id == albumId }
                )
                descriptor.fetchLimit = 1
                
                guard let cached = try context.fetch(descriptor).first,
                      cached.cachedAt.distance(to: Date()) < swiftDataConfig.cacheTTL
                else {
                    throw NotFoundError()
                }
                
                return .init(from: cached)
            }
        )
    )
}
