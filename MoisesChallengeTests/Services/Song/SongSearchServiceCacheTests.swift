import Foundation
import SwiftData
import Testing
@testable import MoisesChallenge

@Suite(.serialized) struct SongSearchServiceCacheTests {

    @Test func search_returnsCachedPageWhenFresh() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let context = ModelContext(container)
        let cachedPage = CachedSongSearchPageSwiftData(
            searchTerm: "beatles",
            offset: 0,
            limit: 2,
            entries: [TestData.song1, TestData.song2]
        )
        context.insert(cachedPage)
        try context.save()

        let service = SongSearchService.Cache(container: container).service

        // ACT
        let page = try await service.search(.first(params: .init(searchTerm: "beatles"), limit: 2))

        // ASSERT
        #expect(page.entries == [TestData.song1, TestData.song2])
        #expect(page.pagination == .first(params: .init(searchTerm: "beatles"), limit: 2))
    }

    @Test func search_throwsNotFoundWhenPageMissing() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let service = SongSearchService.Cache(container: container).service

        // ACT
        do {
            _ = try await service.search(.first(params: .init(searchTerm: "missing"), limit: 2))
            Issue.record("Expected missing cache page to throw NotFoundError")
        } catch {
            // ASSERT
            #expect(error is NotFoundError)
        }
    }

    @Test func search_throwsNotFoundWhenCachedPageExpired() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let context = ModelContext(container)
        context.insert(
            CachedSongSearchPageSwiftData(
                searchTerm: "beatles",
                offset: 0,
                limit: 2,
                entries: [TestData.song1],
                cachedAt: .now.addingTimeInterval(-(swiftDataConfig.cacheTTL + 1))
            )
        )
        try context.save()

        let service = SongSearchService.Cache(container: container).service

        // ACT
        do {
            _ = try await service.search(.first(params: .init(searchTerm: "beatles"), limit: 2))
            Issue.record("Expected expired cache page to throw NotFoundError")
        } catch {
            // ASSERT
            #expect(error is NotFoundError)
        }
    }

    @Test func add_persistsPageForFutureSearch() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let cache = SongSearchService.Cache(container: container)
        let page = SongSearchPage(
            entries: [TestData.song1, TestData.song2],
            pagination: .first(params: .init(searchTerm: "beatles"), limit: 2)
        )

        // ACT
        try cache.add(page: page)

        let stored = try await cache.service.search(.first(params: .init(searchTerm: "beatles"), limit: 2))

        // ASSERT
        #expect(stored == page)
    }
}
