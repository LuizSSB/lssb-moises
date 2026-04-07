//
//  SongSearchService+Cache.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Foundation
import SwiftData

extension SongSearchService {
    struct Cache {
        let container: ModelContainer
        let service: SongSearchService

        init(container: ModelContainer) {
            self.container = container
            service = .init(
                search: { pagination in
                    let context = ModelContext(container)
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
        }

        @Sendable func add(page: SongSearchPage) throws {
            let context = ModelContext(container)
            context.insert(CachedSongSearchPageSwiftData(from: page))
            try context.save()
        }
    }
}
