//
//  SongSearchService+Cache.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Foundation
import SwiftData

extension SongSearchService {
    static let cache = (
        addToCache: { @Sendable (page: SongSearchPage) in
            let context = ModelContext(swiftDataConfig.appModelContainer)
            context.insert(CachedSongSearchPageSwiftData(from: page))
            try context.save()
        },
        service: Self.init(
            search: { pagination in
                let context = ModelContext(swiftDataConfig.appModelContainer)
                let searchTerm = pagination.params.searchTerm
                let offset = pagination.offset
                let limit = pagination.limit
                var descriptor = FetchDescriptor<CachedSongSearchPageSwiftData>(
                    predicate: #Predicate {
                        $0.searchTerm == searchTerm &&
                        $0.offset == offset &&
                        $0.limit == limit
                    }
                )
                descriptor.fetchLimit = 1
                
                guard let cachedPage = try context.fetch(descriptor).first,
                      cachedPage.cachedAt.distance(to: Date()) < swiftDataConfig.cacheTTL
                else {
                    throw NotFoundError()
                }
                
                return .init(from: cachedPage)
            }
        )
    )
}
