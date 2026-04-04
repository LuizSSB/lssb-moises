import Foundation
import Testing
@testable import MoisesChallenge

@Suite(.serialized) struct AlbumSearchServiceHybridTests {

    @Test func get_returnsCachedAlbumWhenCacheHit() async throws {
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

        let album = try await service.get(TestData.album.id)
        #expect(album == TestData.album)
    }

    @Test func get_returnsFreshAlbumAndCachesItWhenCacheMiss() async throws {
        let container = try makeTestModelContainer()
        let cache = AlbumSearchService.Cache(container: container)
        let service = AlbumSearchService(
            cache: cache,
            actual: .init(get: { _ in TestData.album })
        )

        let album = try await service.get(TestData.album.id)
        let cached = try await cache.service.get(TestData.album.id)

        #expect(album == TestData.album)
        #expect(cached == TestData.album)
    }
}
