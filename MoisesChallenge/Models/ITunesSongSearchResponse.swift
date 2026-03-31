//
//  ITunesSongSearchResponse.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

struct ITunesSongSearchResponse: Decodable {
    let resultCount: Int
    let results: [Song]
}
