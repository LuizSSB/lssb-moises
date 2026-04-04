import Foundation
import SwiftData
import Testing
@testable import MoisesChallenge

@Suite(.serialized) struct InteractionServiceTests {

    @Test func markPlayed_persistsInteractionAndEmitsEvent() async throws {
        let container = try makeTestModelContainer()
        let service = InteractionService(with: container)
        let (_, stream) = await service.songMarkedPlayedEvent.stream()

        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        try await service.markPlayed(TestData.song1)

        let context = ModelContext(container)
        let saved = try context.fetch(FetchDescriptor<SongInteractionSwiftData>())

        #expect(saved.count == 1)
        #expect(Song(from: saved.first!.storedSong) == TestData.song1)
        #expect(await reader.value?.song == TestData.song1)
    }

    @Test func listPlayedSongs_returnsEntriesSortedByLastPlayedAtDescendingWithPagination() async throws {
        let container = try makeTestModelContainer()
        let service = InteractionService(with: container)

        try await service.markPlayed(TestData.song1)
        try await Task.sleep(for: .milliseconds(10))
        try await service.markPlayed(TestData.song3)
        try await Task.sleep(for: .milliseconds(10))
        try await service.markPlayed(TestData.song2)

        let page = try await service.listPlayedSongs(.init(offset: 1, limit: 1))

        #expect(page.entries.count == 1)
        #expect(page.entries.first?.song == TestData.song3)
        #expect(page.pagination.offset == 1)
        #expect(page.pagination.limit == 1)
    }
}
