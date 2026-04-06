//
//  PaginatedListPlaybackQueueTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 04/04/26.
//

import Foundation
import Observation
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
            let loadNextPageCallCount = await list.recordedLoadNextPageCallCount()
            return loadNextPageCallCount == 1
        }

        // ACT
        list.items = [TestData.song1, TestData.song2, TestData.song3]
        list.latestResult = Page(entries: [TestData.song3], pagination: .init(offset: 2, limit: 2))
        let latestResult = try #require(list.latestResult)
        list.lastLoadResult = .success(latestResult.entries)
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
            let loadNextPageCallCount = await list.recordedLoadNextPageCallCount()
            return loadNextPageCallCount == 1
        }

        // ACT
        list.lastLoadResult = .failure(InvalidDataError())
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
            let loadNextPageCallCount = await list.recordedLoadNextPageCallCount()
            return loadNextPageCallCount == 1
        }

        // ACT

        // ASSERT
        #expect(queue.isLoading(.next))
        #expect(!queue.isLoading(.previous))

        // ACT
        list.items = [TestData.song1, TestData.song2, TestData.song3]
        list.latestResult = Page(entries: [TestData.song3], pagination: .init(offset: 2, limit: 2))
        if let latestResult = list.latestResult {
            list.lastLoadResult = .success(latestResult.entries)
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
            latestResult: Page(entries: [TestData.song1, TestData.song2], pagination: .init(offset: 0, limit: 2))
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
        list.items = [TestData.song1, TestData.song2, TestData.song3]
        list.latestResult = Page(entries: [TestData.song3], pagination: .init(offset: 2, limit: 2))
        let latestResult = try #require(list.latestResult)
        list.lastLoadResult = .success(latestResult.entries)
        try await moveTask.value

        // ASSERT
        #expect(queue.currentItem == TestData.song1)
        #expect(queue.currentIndex == 0)
    }

    @Test func currentItemObservation_emitsUpdatedSongWhenCurrentIndexChanges() async throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2, TestData.song3])
        let queue = PaginatedListPlaybackQueue(list: list, selectedItem: TestData.song1)
        var observedItem: Song?

        withObservationTracking {
            _ = queue.currentItem
        } onChangeAsync: { @MainActor in
            observedItem = queue.currentItem
        }

        // ACT
        queue.currentIndex = 1

        // ASSERT
        await busyWait { observedItem == TestData.song2 }
        #expect(observedItem == TestData.song2)
    }
}

@MainActor
@Observable
private final class PaginatedListViewModelStub: PaginatedListViewModel {
    var items: [Song]
    var loadState: PaginatedListLoadState = .loaded
    var hasMore: Bool {
        latestResult?.hasMore ?? false
    }
    var latestResult: Pagination<NullPaginationParams>.Page<Song>?
    var lastLoadResult: Result<[Song], Error>?
    private(set) var loadNextPageCallCount = 0

    init(
        items: [Song],
        latestResult: Pagination<NullPaginationParams>.Page<Song>? = nil
    ) {
        self.items = items
        self.latestResult = latestResult
    }

    func loadFirstPageIfNeeded() {
    }

    func loadNextPage() {
        loadNextPageCallCount += 1
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
