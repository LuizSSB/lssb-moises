//
//  SongSearchService+Cache.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

extension SongSearchService {
    static let cache = (
        addToCache: { @Sendable (query: String, results: [Song]) in
            // TODO
        },
        service: Self.init(
            search: { pagination in
                // TODO
                return .init(entries: [], pagination: .first(params: .init(searchTerm: "")))
            }
        )
    )
}
