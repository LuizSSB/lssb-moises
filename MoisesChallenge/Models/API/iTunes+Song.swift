//
//  iTunes+Song.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

extension Song {
    init?(fromResponseResult r: ITunesAPIResponse.Result, checkWrapperType: Bool = true) {
        guard let trackId = r.trackId,
              !checkWrapperType || r.wrapperType == .track
        else { return nil }
        
        self = Song(
            id: String(trackId),
            title: r.trackName,
            artist: {
                if let artistId = r.artistId {
                    return .init(id: String(artistId), name: r.artistName)
                }
                return nil
            }(),
            album: Album(fromResponseResult: r, checkWrapperType: false),
            itemArtwork: r.artworkUrl30,
            mainArtwork: r.artworkUrl100,
            durationSeconds: {
                if let trackTimeMillis = r.trackTimeMillis {
                    return Double(trackTimeMillis) / 1000
                }
                return nil
            }(),
            preview: r.previewUrl
        )
    }
}
