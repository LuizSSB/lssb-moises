import Foundation
import Testing
@testable import MoisesChallenge

@Suite(.serialized) struct AlbumSearchServiceTests {

    @Test func get_requestsAlbumAndParsesSongs() async throws {
        // ARRANGE
        let session = MockNetwork.makeSession { request in
            #expect(request.url?.absoluteString.contains("itunes.apple.com/lookup") == true)
            #expect(request.url?.query?.contains("id=42") == true)
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(
                """
                {
                  "resultCount": 3,
                  "results": [
                    {
                      "wrapperType": "collection",
                      "collectionId": 42,
                      "artistId": 10,
                      "artistName": "The Beatles",
                      "collectionName": "Album A",
                      "artworkUrl30": "https://example.com/a-30.jpg",
                      "artworkUrl100": "https://example.com/a-100.jpg"
                    },
                    {
                      "wrapperType": "track",
                      "trackId": 1,
                      "artistId": 10,
                      "artistName": "The Beatles",
                      "trackName": "Song A",
                      "collectionId": 42,
                      "collectionName": "Album A",
                      "artworkUrl30": "https://example.com/a-30.jpg",
                      "artworkUrl100": "https://example.com/a-100.jpg",
                      "trackTimeMillis": 1000,
                      "previewUrl": "https://example.com/a.m4a"
                    },
                    {
                      "wrapperType": "track",
                      "trackId": 2,
                      "artistId": 10,
                      "artistName": "The Beatles",
                      "trackName": "Song B",
                      "collectionId": 42,
                      "collectionName": "Album A",
                      "artworkUrl30": "https://example.com/b-30.jpg",
                      "artworkUrl100": "https://example.com/b-100.jpg",
                      "trackTimeMillis": 2000,
                      "previewUrl": "https://example.com/b.m4a"
                    }
                  ]
                }
                """.utf8
            )
            return (response, data)
        }
        defer { MockNetwork.reset() }

        // ACT
        let album = try await AlbumSearchService(iTunesAPISession: session).get("42")

        // ASSERT
        #expect(album.id == "42")
        #expect(album.title == "Album A")
        #expect(album.songs?.map(\.id) == ["1", "2"])
    }

    @Test func get_throwsNotFoundWhenResponseIsEmpty() async throws {
        // ARRANGE
        let session = MockNetwork.makeSession { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(
                """
                {
                  "resultCount": 0,
                  "results": []
                }
                """.utf8
            )
            return (response, data)
        }
        defer { MockNetwork.reset() }

        // ACT
        do {
            _ = try await AlbumSearchService(iTunesAPISession: session).get("42")
            Issue.record("Expected empty album lookup response to throw NotFoundError")
        } catch {
            // ASSERT
            #expect(error is NotFoundError)
        }
    }
}
