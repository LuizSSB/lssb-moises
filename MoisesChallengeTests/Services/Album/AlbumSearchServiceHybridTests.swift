import Foundation
@testable import MoisesChallenge
import Testing

@Suite(.serialized) struct AlbumSearchServiceHybridTests {
    @Test func get_returnsCachedAlbumWhenCacheHit() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let cache = AlbumSearchService.Cache(container: container)
        try cache.add(album: TestData.album)

        let service = AlbumSearchService(
            cache: cache,
            actual: .init(
                get: { _ in
                    Issue.record("Actual service should not be called when cache has a fresh album")
                    return TestData.album
                }
            )
        )

        // ACT
        let album = try await service.get(TestData.album.id)

        // ASSERT
        #expect(album == TestData.album)
    }

    @Test func get_returnsFreshAlbumAndCachesItWhenCacheMiss() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let cache = AlbumSearchService.Cache(container: container)
        let service = AlbumSearchService(
            cache: cache,
            actual: .init(get: { _ in TestData.album })
        )

        // ACT
        let album = try await service.get(TestData.album.id)
        let cached = try await cache.service.get(TestData.album.id)

        // ASSERT
        #expect(album == TestData.album)
        #expect(cached == TestData.album)
    }
}
