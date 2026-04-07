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

    var songMarkedPlayedEvent: Event<SongInteraction>
    var markPlayed: @Sendable (Song) async throws -> Void
    var listPlayedSongs: @Sendable (PlayedSongListPagination) async throws -> PlayedSongListPage
}

extension InteractionService {
    init(with container: ModelContainer) {
        let onSongMarkedPlayed = Event<SongInteraction>()

        self.init(
            songMarkedPlayedEvent: onSongMarkedPlayed,
            markPlayed: { song in
                let context = ModelContext(container)
                let interaction = SongInteractionSwiftData(song: song)
                context.insert(interaction)
                try context.save()

                onSongMarkedPlayed.emitAndForget(.init(from: interaction))
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
                        limit: pagination.limit
                    )
                )
            }
        )
    }

    static let swiftData = Self(with: swiftDataConfig.appModelContainer)
}
