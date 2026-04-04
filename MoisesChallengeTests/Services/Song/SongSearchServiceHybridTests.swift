import Foundation
import Testing
@testable import MoisesChallenge

@Suite(.serialized) struct SongSearchServiceHybridTests {

    @Test func search_returnsCachedPageWhenCacheHit() async throws {
        let container = try makeTestModelContainer()
        let cache = SongSearchService.Cache(container: container)
        let cachedPage = SongSearchPage(
            entries: [TestData.song1],
            pagination: .first(params: .init(searchTerm: "beatles"), limit: 1)
        )
        try cache.add(page: cachedPage)

        let service = SongSearchService(
            cache: cache,
            actual: .init(
                search: { _ in
                    Issue.record("Actual service should not be called when cache has a fresh page")
                    return cachedPage
                }
            )
        )

        let page = try await service.search(.first(params: .init(searchTerm: "beatles"), limit: 1))
        #expect(page == cachedPage)
    }

    @Test func search_returnsFreshPageAndCachesItWhenCacheMiss() async throws {
        let container = try makeTestModelContainer()
        let cache = SongSearchService.Cache(container: container)
        let expectedPage = SongSearchPage(
            entries: [TestData.song2, TestData.song3],
            pagination: .first(params: .init(searchTerm: "queen"), limit: 2)
        )
        let service = SongSearchService(
            cache: cache,
            actual: .init(search: { _ in expectedPage })
        )

        let page = try await service.search(.first(params: .init(searchTerm: "queen"), limit: 2))
        let cached = try await cache.service.search(.first(params: .init(searchTerm: "queen"), limit: 2))

        #expect(page == expectedPage)
        #expect(cached == expectedPage)
    }
}
