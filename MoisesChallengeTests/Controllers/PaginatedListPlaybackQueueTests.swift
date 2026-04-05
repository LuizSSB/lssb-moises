//
//  PaginatedListPlaybackQueueTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 04/04/26.
//

import Foundation
import Testing
@testable import MoisesChallenge

@MainActor
struct PaginatedListPlaybackQueueTests {
    typealias Page = Pagination<NullPaginationParams>.Page<Song>

    @Test func init_setsCurrentItemToSelectedSong() {
        // ARRANGE
        let list = PaginatedListViewModelStub(
            items: [TestData.song1, TestData.song2],
            latestResult: Page(entries: [TestData.song1, TestData.song2], pagination: .init(offset: 0, limit: 2))
        )

        // ACT
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)

        // ASSERT
        #expect(queue.currentItem == TestData.song2)
        #expect(queue.currentIndex == 1)
    }

    @Test func currentIndex_returnsNilWhenCurrentSongIsNotInLoadedItems() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song3)

        // ACT

        // ASSERT
        #expect(queue.currentIndex == nil)
    }

    @Test func currentIndex_setsCurrentItemWhenIndexIsValid() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2, TestData.song3])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song1)

        // ACT
        queue.currentIndex = 2

        // ASSERT
        #expect(queue.currentItem == TestData.song3)
        #expect(queue.currentIndex == 2)
    }

    @Test func currentIndex_clearsCurrentItemWhenSetToNil() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song1)

        // ACT
        queue.currentIndex = nil

        // ASSERT
        #expect(queue.currentItem == nil)
        #expect(queue.currentIndex == nil)
    }

    @Test func currentIndex_ignoresInvalidIndexes() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song1)

        // ACT
        queue.currentIndex = -1

        // ASSERT
        #expect(queue.currentItem == TestData.song1)
        #expect(queue.currentIndex == 0)

        // ACT
        queue.currentIndex = 2

        // ASSERT
        #expect(queue.currentItem == TestData.song1)
        #expect(queue.currentIndex == 0)
    }

    @Test func has_returnsWhetherPreviousAndNextSongsExistInLoadedItems() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2, TestData.song3])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)

        // ACT

        // ASSERT
        #expect(queue.has(.previous))
        #expect(queue.has(.next))
    }

    @Test func has_returnsFalseForPreviousWhenCurrentSongIsFirstLoadedItem() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song1)

        // ACT

        // ASSERT
        #expect(!queue.has(.previous))
    }

    @Test func has_returnsTrueForNextWhenAtLastLoadedSongAndLatestPageHasMore() {
        // ARRANGE
        let list = PaginatedListViewModelStub(
            items: [TestData.song1, TestData.song2],
            latestResult: Page(entries: [TestData.song1, TestData.song2], pagination: .init(offset: 0, limit: 2))
        )
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)

        // ACT

        // ASSERT
        #expect(queue.has(.next))
    }

    @Test func has_returnsFalseForNextWhenAtLastLoadedSongAndLatestPageHasNoMore() {
        // ARRANGE
        let list = PaginatedListViewModelStub(
            items: [TestData.song1],
            latestResult: Page(entries: [TestData.song1], pagination: .init(offset: 0, limit: 2))
        )
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song1)

        // ACT

        // ASSERT
        #expect(!queue.has(.next))
    }

    @Test func move_movesToPreviousLoadedSong() async throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2, TestData.song3])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)

        // ACT
        try await queue.move(to: .previous)

        // ASSERT
        #expect(queue.currentItem == TestData.song1)
    }

    @Test func move_movesToNextLoadedSong() async throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2, TestData.song3])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)

        // ACT
        try await queue.move(to: .next)

        // ASSERT
        #expect(queue.currentItem == TestData.song3)
    }

    @Test func move_keepsCurrentSongWhenMovingPreviousFromFirstItem() async throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song1)

        // ACT
        try await queue.move(to: .previous)

        // ASSERT
        #expect(queue.currentItem == TestData.song1)
    }

    @Test func move_keepsCurrentSongWhenCurrentSongIsNotInLoadedItems() async throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song3)

        // ACT
        try await queue.move(to: .next)

        // ASSERT
        #expect(queue.currentItem == TestData.song3)
        #expect(list.loadNextPageCallCount == 0)
    }

    @Test func move_loadsNextPageAndMovesToFirstNewSongWhenNextSongIsNotLoadedYet() async throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(
            items: [TestData.song1, TestData.song2],
            latestResult: Page(entries: [TestData.song1, TestData.song2], pagination: .init(offset: 0, limit: 2))
        )
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)

        let moveTask = Task {
            try await queue.move(to: .next)
        }

        await busyWaitAsync {
            let observerCount = await list.pageLoadedEvent.observerCount
            let loadNextPageCallCount = await list.recordedLoadNextPageCallCount()
            return loadNextPageCallCount == 1 && observerCount > 0
        }

        // ACT
        list.items = [TestData.song1, TestData.song2, TestData.song3]
        list.latestResult = Page(entries: [TestData.song3], pagination: .init(offset: 2, limit: 2))
        let latestResult = try #require(list.latestResult)
        await list.pageLoadedEvent.emit(.success(latestResult))
        try await moveTask.value

        // ASSERT
        #expect(queue.currentItem == TestData.song3)
        #expect(queue.currentIndex == 2)
    }

    @Test func move_throwsAndKeepsCurrentSongWhenNextPageLoadFails() async {
        // ARRANGE
        let list = PaginatedListViewModelStub(
            items: [TestData.song1, TestData.song2],
            latestResult: Page(entries: [TestData.song1, TestData.song2], pagination: .init(offset: 0, limit: 2))
        )
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)
        let moveTask = Task<Result<Void, Error>, Never> {
            do {
                try await queue.move(to: .next)
                return .success(())
            } catch {
                return .failure(error)
            }
        }

        await busyWaitAsync {
            let observerCount = await list.pageLoadedEvent.observerCount
            let loadNextPageCallCount = await list.recordedLoadNextPageCallCount()
            return loadNextPageCallCount == 1 && observerCount > 0
        }

        // ACT
        await list.pageLoadedEvent.emit(.failure(InvalidDataError()))
        let result = await moveTask.value

        // ASSERT
        switch result {
        case .success:
            Issue.record("Expected moving to the next page to fail.")
        case .failure(let error):
            #expect(error is InvalidDataError)
        }
        #expect(queue.currentItem == TestData.song2)
        #expect(queue.currentIndex == 1)
    }

    @Test func isLoading_returnsTrueOnlyWhileNextPageIsBeingLoadedFromLastLoadedSong() async {
        // ARRANGE
        let list = PaginatedListViewModelStub(
            items: [TestData.song1, TestData.song2],
            latestResult: Page(entries: [TestData.song1, TestData.song2], pagination: .init(offset: 0, limit: 2))
        )
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)

        let moveTask = Task {
            try await queue.move(to: .next)
        }

        await busyWaitAsync {
            let observerCount = await list.pageLoadedEvent.observerCount
            let loadNextPageCallCount = await list.recordedLoadNextPageCallCount()
            return loadNextPageCallCount == 1 && observerCount > 0
        }

        // ACT

        // ASSERT
        #expect(queue.isLoading(.next))
        #expect(!queue.isLoading(.previous))

        // ACT
        list.items = [TestData.song1, TestData.song2, TestData.song3]
        list.latestResult = Page(entries: [TestData.song3], pagination: .init(offset: 2, limit: 2))
        if let latestResult = list.latestResult {
            await list.pageLoadedEvent.emit(.success(latestResult))
        } else {
            Issue.record("Expected the stub to have a latest result before emitting success.")
        }
        try? await moveTask.value

        // ASSERT
        #expect(!queue.isLoading(.next))
    }

    @Test func move_loadsNextPageAndAndDoesNotMoveToFirstNewSongBecauseUserChangedCurrentSongWhileLoading() async throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(
            items: [TestData.song1, TestData.song2],
            latestResult: Page(entries: [TestData.song1, TestData.song2], pagination: .init(offset: 0, limit: 2)),
            intervalBetweenLoads: 0.5
        )
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song2)

        let moveTask = Task {
            try await queue.move(to: .next)
        }

        await busyWaitAsync {
            let loadNextPageCallCount = await list.recordedLoadNextPageCallCount()
            return loadNextPageCallCount == 1
        }
        queue.currentIndex = 0

        // ACT
        list.latestResult = Page(entries: [TestData.song3], pagination: .init(offset: 2, limit: 2))
        let latestResult = try #require(list.latestResult)
        await list.pageLoadedEvent.emit(.success(latestResult))
        try await moveTask.value

        // ASSERT
        #expect(queue.currentItem == TestData.song1)
        #expect(queue.currentIndex == 0)
    }

    @Test func currentItemChangedEvent_emitsUpdatedSongWhenCurrentIndexChanges() async throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2, TestData.song3])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song1)
        let (_, stream) = await queue.currentItemChangedEvent.stream()
        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        // ACT
        queue.currentIndex = 1

        // ASSERT
        #expect(await reader.value == TestData.song2)
    }
}

@MainActor
private final class PaginatedListViewModelStub: PaginatedListViewModel {
    var items: [Song]
    var loadState: PaginatedListLoadState = .loaded
    var latestResult: Pagination<NullPaginationParams>.Page<Song>?
    var pageLoadedEvent = Event<Result<Pagination<NullPaginationParams>.Page<Song>, Error>>()
    private(set) var loadNextPageCallCount = 0
    var intervalBetweenLoads: TimeInterval = 0

    init(
        items: [Song],
        latestResult: Pagination<NullPaginationParams>.Page<Song>? = nil,
        intervalBetweenLoads: Double = 0
    ) {
        self.items = items
        self.latestResult = latestResult
        self.intervalBetweenLoads = intervalBetweenLoads
    }

    func loadFirstPageIfNeeded() {
    }

    func loadNextPage() {
        if intervalBetweenLoads == 0 {
            loadNextPageCallCount += 1
        } else {
            Task {
                try? await Task.sleep(for: .seconds(intervalBetweenLoads))
                loadNextPageCallCount += 1
            }
        }
    }

    func recordedLoadNextPageCallCount() -> Int {
        loadNextPageCallCount
    }

    func refresh() async {
    }

    func interactWithError(shouldRetry: Bool) {
    }

    func reset() {
    }
}
