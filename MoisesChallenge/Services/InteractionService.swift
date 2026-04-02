//
//  InteractionService.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Foundation
import SwiftData

struct InteractionService {
    typealias PlayedSongListPagination = Pagination<NullPaginationParams>
    typealias PlayedSongListPage = PlayedSongListPagination.Page<SongInteraction>
    
    var markPlayed: @Sendable (Song) async throws -> Void
    var listPlayedSongs: @Sendable (PlayedSongListPagination) async throws -> PlayedSongListPage
}

extension InteractionService {
    static func swiftData(container: ModelContainer = appModelContainer) -> Self {
        Self(
            markPlayed: { song in
                let context = ModelContext(container)
                
                var descriptor = FetchDescriptor<SongInteractionSwiftData>(
                    predicate: #Predicate { $0.song.id == song.id }
                )
                descriptor.fetchLimit = 1
                
                if let existing = try context.fetch(descriptor).first {
                    existing.lastPlayedAt = .now
                } else {
                    context.insert(SongInteractionSwiftData(song: song))
                }
                
                try context.save()
            },
            listPlayedSongs: { pagination in
                let context = ModelContext(container)
                
                var descriptor = FetchDescriptor<SongInteractionSwiftData>(
                    sortBy: [SortDescriptor(\.lastPlayedAt, order: .reverse)]
                )
                descriptor.fetchOffset = pagination.offset
                descriptor.fetchLimit = pagination.limit
                
                let interactionsData = try context.fetch(descriptor)
                let interactions = interactionsData.map(SongInteraction.init(from:))
                return .init(
                    entries: interactions,
                    pagination: .init(
                        offset: pagination.offset,
                        limit: interactionsData.count
                    )
                )
            }
        )
    }
}
