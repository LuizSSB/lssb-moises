//
//  AlbumSearchService+Cache.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

extension AlbumSearchService {
    struct Cache {
        let container: ModelContainer
        let service: AlbumSearchService
        
        init(container: ModelContainer) {
            self.container = container
            self.service = .init(
                get: { albumId in
                    let context = ModelContext(container)
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
        }
        
        @Sendable func add(album: Album) throws{
            guard let cached = CachedAlbumSwiftData(from: album) else { return }
            
            let context = ModelContext(container)
            context.insert(cached)
            try context.save()
        }
    }
}
