//
//  StaticPlaybackQueueTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 04/04/26.
//

import Testing
@testable import MoisesChallenge

@MainActor
struct StaticPlaybackQueueTests {

    @Test func init_returnsNilWhenSelectedItemIsNotInNonEmptyItems() {
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 4)

        #expect(queue == nil)
    }

    @Test func init_createsQueueWhenItemsAreEmpty() {
        let queue = StaticPlaybackQueue(items: [Int](), selectedItem: 1)

        #expect(queue != nil)
        #expect(queue?.currentItem == 1)
        #expect(queue?.currentIndex == nil)
    }

    @Test func currentIndex_returnsIndexOfCurrentItem() throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2))

        #expect(queue.currentIndex == 1)
    }

    @Test func currentIndex_setsCurrentItemWhenIndexIsValid() throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1))

        queue.currentIndex = 2

        #expect(queue.currentItem == 3)
        #expect(queue.currentIndex == 2)
    }

    @Test func currentIndex_clearsCurrentItemWhenSetToNil() throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2))

        queue.currentIndex = nil

        #expect(queue.currentItem == nil)
        #expect(queue.currentIndex == nil)
    }

    @Test func currentIndex_ignoresOutOfBoundsValues() throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2))

        queue.currentIndex = -1
        #expect(queue.currentItem == 2)
        #expect(queue.currentIndex == 1)

        queue.currentIndex = 3
        #expect(queue.currentItem == 2)
        #expect(queue.currentIndex == 1)
    }

    @Test func has_returnsWhetherPreviousAndNextItemsExist() throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2))

        #expect(queue.has(.previous))
        #expect(queue.has(.next))
    }

    @Test func has_returnsFalseForPreviousAtFirstItem() throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1))

        #expect(!queue.has(.previous))
    }

    @Test func has_returnsFalseForNextAtLastItem() throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 3))

        #expect(!queue.has(.next))
    }

    @Test func move_movesToPreviousItem() async throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2))

        try await queue.move(to: .previous)

        #expect(queue.currentItem == 1)
    }

    @Test func move_movesToNextItem() async throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2))

        try await queue.move(to: .next)

        #expect(queue.currentItem == 3)
    }

    @Test func move_keepsCurrentItemWhenMovingPreviousFromFirstItem() async throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1))

        try await queue.move(to: .previous)

        #expect(queue.currentItem == 1)
    }

    @Test func move_keepsCurrentItemWhenMovingNextFromLastItem() async throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 3))

        try await queue.move(to: .next)

        #expect(queue.currentItem == 3)
    }

    @Test func move_selectsFirstItemWhenCurrentItemIsNil() async throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1))
        queue.currentIndex = nil

        try await queue.move(to: .next)

        #expect(queue.currentItem == 1)
    }

    @Test func moveToFirst_selectsFirstItem() throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 3))

        queue.moveToFirst()

        #expect(queue.currentItem == 1)
    }

    @Test func currentItemChangedEvent_emitsUpdatedItemWhenCurrentIndexChanges() async throws {
        let queue = try #require(StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1))
        let (_, stream) = await queue.currentItemChangedEvent.stream()

        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        queue.currentIndex = 1

        #expect(await reader.value == 2)
    }
}
