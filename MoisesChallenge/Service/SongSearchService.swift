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
        let artistName: String?
        let trackName: String?
        let artworkUrl30: String?
        let artworkUrl100: String?
        let trackTimeMillis: Int?
        let previewUrl: String?
    }
    
    let resultCount: Int
    let results: [Item]
}

// Values per docs
private let urlITunes = "https://itunes.apple.com/search"
private let defaultITunesMedia = "music"
private let defaultITunesEntity = "song"
private let defaultITunesAPILimit = 50
private let maxITunesAPILimit = 200

struct SongSearchService {
    struct SearchParams: Equatable, Hashable {
        let searchTerm: String
        fileprivate var allResults: [Song]?
    }
    
    typealias SearchPagination = MoisesChallenge.Pagination<SearchParams>
    typealias SearchPage = Self.SearchPagination.Page<Song>
    
    /// Lists all songs with pagination.
    /// The iTunes API doesn't support pagination (only limit), so by default we can't have that. In addition, we also can't simulate pagination by increasing the limit and cutting off all entries prior to the offset, because the position of songs in the results may shift when the limit changes.
    /// If we want to have that sweet infinite scroll action in the view (not necessary in prod, but perhaps necessary for a job application challenge), the way is to simulate pagination: in the first query for some term we actually query everything and then we just return slices of the list.
    var search = {
        (_ pagination: SearchPagination) async throws -> SearchPage in
        
        let limit = pagination.limit ?? defaultITunesAPILimit
        
        if let allResults = pagination.params.allResults {
            try? await Task.sleep(for: .seconds(3)) // just for the thrill
            
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
            urlITunes,
            parameters: [
                "term": pagination.params.searchTerm,
                "limit": maxITunesAPILimit,
                "media": defaultITunesMedia,
                "entity": defaultITunesEntity
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
                    title: $0.trackName,
                    itemArtwork: $0.artworkUrl30,
                    mainArtwork: $0.artworkUrl100,
                    durationSeconds: {
                        if let trackTimeMillis = $0.trackTimeMillis {
                            return Double(trackTimeMillis) / 1000
                        }
                        return nil
                    }($0),
                    preview: $0.previewUrl
                )
            }
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
            throw error
        }
    }
}

extension SongSearchService.SearchParams {
    init(searchTerm: String) {
        self.init(searchTerm: searchTerm, allResults: nil)
    }
}
