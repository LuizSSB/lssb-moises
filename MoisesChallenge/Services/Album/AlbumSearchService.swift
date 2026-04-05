//
//  AlbumSearchService.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Alamofire

struct AlbumSearchService {
    var get: @Sendable (_ albumId: String) async throws -> Album
}

extension AlbumSearchService {
    init(iTunesAPISession: Session) {
        self.init(
            get: { albumId in
                let result = await iTunesAPISession.request(
                    iTunesAPIConfig.urls.lookup,
                    parameters: [
                        "id": albumId,
                        "limit": iTunesAPIConfig.maxLimit,
                        "entity": iTunesAPIConfig.defaults.entity
                    ]
                )
                    .serializingDecodable(ITunesAPIResponse.self)
                    .result
                
                switch result {
                case let .success(response):
                    guard response.resultCount != 0 else { throw NotFoundError() }
                    guard let album = Album(fromResponse: response) else { throw InvalidDataError() }
                    return album
                case let .failure(error):
                    throw parseAF(error: error)
                }
            }
        )
    }
    
    static let iTunes = Self(iTunesAPISession: AF)
}
