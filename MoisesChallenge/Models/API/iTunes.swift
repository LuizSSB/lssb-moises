//
//  iTunes.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

// NOTE: technically, it would be more appropriate to define `ITunesResponse` as an enum with cases for each specific `WrapperType`. However, our usage of it here is so limited that it wouldn't be worth the effort - specially considering just how bad the docs are in explaining all the possible variations and all.
struct ITunesAPIResponse: Codable {
    enum WrapperType: String, Codable {
        case collection,
             track
    }

    struct Result: Codable {
        let wrapperType: WrapperType
        let trackId: Int?
        let artistId: Int?
        let artistName: String?
        let trackName: String?
        let collectionId: Int?
        let collectionName: String?
        let artworkUrl30: String?
        let artworkUrl100: String?
        let trackTimeMillis: Int?
        let previewUrl: String?
    }

    let resultCount: Int
    let results: [Result]
}
