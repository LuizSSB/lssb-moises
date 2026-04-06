import Foundation
import SwiftData
import Testing
@testable import MoisesChallenge

@Suite(.serialized) struct InteractionServiceTests {

    @Test func markPlayed_persistsInteractionAndEmitsEvent() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let service = InteractionService(with: container)
        let (_, stream) = await service.songMarkedPlayedEvent.stream()

        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        // ACT
        try await service.markPlayed(TestData.song1)

        let context = ModelContext(container)
        let saved = try context.fetch(FetchDescriptor<SongInteractionSwiftData>())

        // ASSERT
        #expect(saved.count == 1)
        #expect(Song(from: saved.first!.storedSong) == TestData.song1)
        #expect(await reader.value?.song == TestData.song1)
    }

    @Test func listPlayedSongs_returnsEntriesSortedByLastPlayedAtDescendingWithPagination() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let service = InteractionService(with: container)

        // ACT
        try await service.markPlayed(TestData.song1)
        try await Task.sleep(for: .milliseconds(10))
        try await service.markPlayed(TestData.song3)
        try await Task.sleep(for: .milliseconds(10))
        try await service.markPlayed(TestData.song2)

        let page = try await service.listPlayedSongs(.init(offset: 1, limit: 1))

        // ASSERT
        #expect(page.entries.count == 1)
        #expect(page.entries.first?.song == TestData.song3)
        #expect(page.pagination.offset == 1)
        #expect(page.pagination.limit == 1)
    }

    @Test func markPlayed_linksStoredSongBackToItsInteraction() async throws {
        // ARRANGE
        let container = try makeTestModelContainer()
        let service = InteractionService(with: container)

        // ACT
        try await service.markPlayed(TestData.song1)

        let context = ModelContext(container)
        let storedInteraction = try #require(try context.fetch(FetchDescriptor<SongInteractionSwiftData>()).first)

        // ASSERT
        #expect(storedInteraction.storedSong.interaction?.persistentModelID == storedInteraction.persistentModelID)
        #expect(Song(from: storedInteraction.storedSong) == TestData.song1)
    }
}
