//
//  iTunes+Album.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

extension Album {
    init?(fromResponse r: ITunesAPIResponse) {
        let albumsInResponse = r.results.compactMap { Self(fromResponseResult: $0) }
        if albumsInResponse.count != 1 {
            return nil
        }

        var album = albumsInResponse.first!
        album.songs = r.results.compactMap { Song(fromResponseResult: $0) }
        self = album
    }

    init?(fromResponseResult r: ITunesAPIResponse.Result, checkWrapperType: Bool = true) {
        guard let collectionId = r.collectionId,
              !checkWrapperType || r.wrapperType == .collection
        else { return nil }

        self = Album(
            id: String(collectionId),
            title: r.collectionName,
            artist: {
                if let artistId = r.artistId {
                    return .init(id: String(artistId), name: r.artistName)
                }
                return nil
            }(),
            itemArtwork: r.artworkUrl30,
            mainArtwork: r.artworkUrl100,
        )
    }
}
