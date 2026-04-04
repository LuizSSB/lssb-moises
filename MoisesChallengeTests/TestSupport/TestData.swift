import Foundation
@testable import MoisesChallenge

enum TestData {
    static let artist = Artist(id: "artist-1", name: "Test Artist")
    static let song1 = Song(
        id: "song-1",
        title: "First Song",
        artist: artist,
        album: nil,
        itemArtwork: "https://example.com/song-1-small.jpg",
        mainArtwork: "https://example.com/song-1-large.jpg",
        durationSeconds: 180,
        preview: "https://example.com/song-1.m4a"
    )
    static let song2 = Song(
        id: "song-2",
        title: "Second Song",
        artist: artist,
        album: nil,
        itemArtwork: "https://example.com/song-2-small.jpg",
        mainArtwork: "https://example.com/song-2-large.jpg",
        durationSeconds: 220,
        preview: "https://example.com/song-2.m4a"
    )
    static let song3 = Song(
        id: "song-3",
        title: "Third Song",
        artist: artist,
        album: nil,
        itemArtwork: "https://example.com/song-3-small.jpg",
        mainArtwork: "https://example.com/song-3-large.jpg",
        durationSeconds: 200,
        preview: "https://example.com/song-3.m4a"
    )
    static let album = Album(
        id: "album-1",
        title: "Test Album",
        artist: artist,
        itemArtwork: "https://example.com/album-small.jpg",
        mainArtwork: "https://example.com/album-large.jpg",
        songs: [song1, song2]
    )
}
