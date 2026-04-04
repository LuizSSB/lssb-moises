import Foundation
import SwiftData
import Testing
@testable import MoisesChallenge

@Suite(.serialized) struct AlbumSearchServiceCacheTests {

    @Test func get_returnsCachedAlbumWhenFresh() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let context = ModelContext(container)
        context.insert(try #require(CachedAlbumSwiftData(from: TestData.album)))
        try context.save()

        let service = AlbumSearchService.Cache(container: container).service

        // ACT
        let album = try await service.get(TestData.album.id)

        // ASSERT
        #expect(album == TestData.album)
    }

    @Test func get_throwsNotFoundWhenAlbumMissing() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let service = AlbumSearchService.Cache(container: container).service

        // ACT
        do {
            _ = try await service.get("missing")
            Issue.record("Expected missing cached album to throw NotFoundError")
        } catch {
            // ASSERT
            #expect(error is NotFoundError)
        }
    }

    @Test func get_throwsNotFoundWhenAlbumExpired() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let context = ModelContext(container)
        context.insert(
            try #require(CachedAlbumSwiftData(
                from: TestData.album,
                cachedAt: .now.addingTimeInterval(-(swiftDataConfig.cacheTTL + 1))
            ))
        )
        try context.save()

        let service = AlbumSearchService.Cache(container: container).service

        // ACT
        do {
            _ = try await service.get(TestData.album.id)
            Issue.record("Expected expired cached album to throw NotFoundError")
        } catch {
            // ASSERT
            #expect(error is NotFoundError)
        }
    }

    @Test func add_persistsAlbumForFutureGet() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let cache = AlbumSearchService.Cache(container: container)

        // ACT
        try cache.add(album: TestData.album)

        let stored = try await cache.service.get(TestData.album.id)

        // ASSERT
        #expect(stored == TestData.album)
    }
}
