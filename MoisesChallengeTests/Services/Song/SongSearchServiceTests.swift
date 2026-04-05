import Foundation
import Testing
@testable import MoisesChallenge

@Suite(.serialized) struct SongSearchServiceTests {

    @Test func search_requestsSongsAndReturnsPaginatedPage() async throws {
        // ARRANGE
        let session = MockNetwork.makeSession { request in
            #expect(request.url?.absoluteString.contains("itunes.apple.com/search") == true)
            #expect(request.url?.query?.contains("term=beatles") == true)
            #expect(request.url?.query?.contains("limit=200") == true)

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
                      "wrapperType": "track",
                      "trackId": 1,
                      "artistId": 10,
                      "artistName": "The Beatles",
                      "trackName": "Song A",
                      "collectionId": 100,
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
                      "collectionId": 100,
                      "collectionName": "Album A",
                      "artworkUrl30": "https://example.com/b-30.jpg",
                      "artworkUrl100": "https://example.com/b-100.jpg",
                      "trackTimeMillis": 2000,
                      "previewUrl": "https://example.com/b.m4a"
                    },
                    {
                      "wrapperType": "track",
                      "trackId": 3,
                      "artistId": 10,
                      "artistName": "The Beatles",
                      "trackName": "Song C",
                      "collectionId": 100,
                      "collectionName": "Album A",
                      "artworkUrl30": "https://example.com/c-30.jpg",
                      "artworkUrl100": "https://example.com/c-100.jpg",
                      "trackTimeMillis": 3000,
                      "previewUrl": "https://example.com/c.m4a"
                    }
                  ]
                }
                """.utf8
            )
            return (response, data)
        }
        defer { MockNetwork.reset() }

        // ACT
        let page = try await SongSearchService(iTunesAPISession: session).search(
            .init(params: .init(searchTerm: "beatles"), offset: 1, limit: 1)
        )

        // ASSERT
        #expect(page.entries.map(\.id) == ["2"])
        #expect(page.entries.first?.title == "Song B")
        #expect(page.pagination.offset == 1)
        #expect(page.pagination.limit == 1)
        #expect(page.pagination.params.searchTerm == "beatles")
        #expect(page.pagination.params.allResults?.count == 3)
    }

    @Test func search_throwsUnderlyingNetworkErrorWhenRequestFails() async throws {
        // ARRANGE
        let expectedError = NSError(
            domain: NSURLErrorDomain,
            code: URLError.notConnectedToInternet.rawValue
        )
        let session = MockNetwork.makeSession { _ in throw expectedError }
        defer { MockNetwork.reset() }

        // ACT
        do {
            _ = try await SongSearchService(iTunesAPISession: session).search(.first(params: .init(searchTerm: "beatles"), limit: 1))
            Issue.record("Expected iTunes search to surface the network error")
        } catch {
            // ASSERT
            let nsError = error as NSError
            #expect(nsError.domain == expectedError.domain)
            #expect(nsError.code == expectedError.code)
        }
    }
}
