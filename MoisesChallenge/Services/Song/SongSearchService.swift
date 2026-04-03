//
//  SongDataSource.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import Alamofire

struct SongSearchService {
    var search: @Sendable (SongSearchPagination) async throws -> SongSearchPage
}

extension SongSearchService {
    static let iTunes = Self(
        /// Lists all songs with pagination.
        /// The iTunes API doesn't support pagination (only limit), so by default we can't have that. In addition, we also can't simulate pagination by increasing the limit and cutting off all entries prior to the offset, because the position of songs in the results may shift when the limit changes.
        /// If we want to have that sweet infinite scroll action in the view (not necessary in prod, but perhaps necessary for a job application challenge), the way is to simulate pagination: in the first query for some term we actually query everything and then we just return slices of the list.
        search: { pagination in
            let limit = pagination.limit ?? iTunesAPIConfig.maxLimit
            
            if let allResults = pagination.params.allResults {
                try? await Task.sleep(for: .seconds(3)) // just for the thrills
                
                return .init(
                    entries: Array(allResults[pagination.offset..<min(allResults.count, pagination.offset + limit)]),
                    pagination: .init(
                        params: pagination.params,
                        offset: pagination.offset,
                        limit: limit
                    )
                )
            }
            
            let result = await AF.request(
                iTunesAPIConfig.urls.search,
                parameters: [
                    "term": pagination.params.searchTerm,
                    "limit": iTunesAPIConfig.maxLimit,
                    "media": iTunesAPIConfig.defaults.media,
                    "entity": iTunesAPIConfig.defaults.entity
                ]
            )
                .serializingDecodable(ITunesAPIResponse.self)
                .result
            
            switch result {
            case let .success(response):
                let songs = response.results.compactMap { Song(fromResponseResult: $0) }
                return .init(
                    entries: Array(songs[pagination.offset..<min(songs.count, pagination.offset + limit)]),
                    pagination: .init(
                        params: .init(
                            searchTerm: pagination.params.searchTerm,
                            allResults: songs
                        ),
                        offset: pagination.offset,
                        limit: limit
                    )
                )
            case let .failure(error):
                throw parseAF(error: error)
            }
        }
    )
}
