//
//  SongDataSource.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import FactoryKit
import Alamofire

struct SongDataSource {
    var list = {
        (_ pagination: Pagination<String>) async throws -> Pagination<String>.Page<Song> in
        
        let response = await AF.request(
            "https://itunes.apple.com/search",
            parameters: [
                "term": pagination.params,
                "limit": pagination.limit,
                "offset": pagination.offset,
                "media": "music",
                "entity": "song"
            ]
        )
        .serializingDecodable(ITunesSongSearchResponse.self)
        .response
        
        switch response.result {
        case let .success(r):
            return .init(entries: r.results, pagination: pagination)
        case let .failure(error):
            throw error
        }
    }
}

extension Container {
    var songDataSource: Factory<SongDataSource> {
        self { SongDataSource() }
            .singleton
    }
}
