//
//  AlbumSearchService.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Alamofire

struct AlbumSearchService {
    var get = { (albumId: String) async throws -> Album in
        let result = await AF.request(
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
            // TODO: what happens if init fails?
            let album = Album(fromResponse: response)!
            return album
        case let .failure(error):
            throw error
        }
    }
}
