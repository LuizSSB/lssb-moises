//
//  SongDataSource.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import FactoryKit
import Alamofire

private struct ITunesSongSearchResponse: Decodable {
    struct Item: Codable, Hashable {
        let trackId: Int
        let artistName: String
        let trackName: String
        let artworkUrl30: String
        let artworkUrl100: String
        let trackTimeMillis: Int
    }
    
    let resultCount: Int
    let results: [Item]
}

// Values per docs
private let defaultITunesAPILimit = 50
private let maxITunesAPILimit = 200

struct SongDataSource {
    struct ListParams: Equatable, Hashable {
        let searchTerm: String
        fileprivate var allResults: [Song]?
    }
    
    typealias Pagination = MoisesChallenge.Pagination<ListParams>
    typealias PaginationResult = Self.Pagination.Page<Song>
    
    /// Lists all songs with pagination.
    /// The iTunes API doesn't support pagination (only limit), so by default we can't have that. In addition, we also can't simulate pagination by increasing the limit and cutting off all entries prior to the offset, because the position of songs in the results may change alongside the limit
    /// If we want to have that sweet infinite scroll action in the view (not necessary in prod, but perhaps necessary for a job application challenge), the way is to simulate pagination: in the first query for some term we actually query everything and then we just sections of the list.
    var list = {
        (_ pagination: Pagination) async throws -> PaginationResult in
        
        let limit = pagination.limit ?? defaultITunesAPILimit
        
        if let allResults = pagination.params.allResults {
            return .init(
                entries: Array(allResults[pagination.offset..<min(allResults.count, pagination.offset + limit)]),
                pagination: .init(
                    params: pagination.params,
                    offset: pagination.offset,
                    limit: limit
                )
            )
        }
        
        let response = await AF.request(
            "https://itunes.apple.com/search",
            parameters: [
                "term": pagination.params.searchTerm,
                "limit": maxITunesAPILimit,
                "media": "music",
                "entity": "song"
            ]
        )
        .serializingDecodable(ITunesSongSearchResponse.self)
        .response
        
        switch response.result {
        case let .success(r):
            let songs = r.results.map {
                Song(
                    id: String($0.trackId),
                    artist: $0.artistName,
                    name: $0.trackName,
                    itemArtwork: $0.artworkUrl30,
                    mainArtwork: $0.artworkUrl100,
                    durationSeconds: Int(Double($0.trackTimeMillis) / 1000)
                )
            }
            return .init(
                entries: Array(songs[pagination.offset..<limit]),
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
            throw error
        }
    }
}

extension SongDataSource.ListParams {
    init(searchTerm: String) {
        self.init(searchTerm: searchTerm, allResults: nil)
    }
}

extension Container {
    var songDataSource: Factory<SongDataSource> {
        self { SongDataSource() }
            .singleton
    }
}
