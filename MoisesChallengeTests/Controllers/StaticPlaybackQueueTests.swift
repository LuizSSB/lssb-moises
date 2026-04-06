//
//  StaticPlaybackQueueTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 04/04/26.
//

import Observation
import Testing
@testable import MoisesChallenge

@MainActor
struct StaticPlaybackQueueTests {

    @Test func init_keepsSelectedItemEvenWhenItIsNotInItems() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 4)

        // ACT

        // ASSERT
        #expect(queue.currentItem == 4)
        #expect(queue.currentIndex == nil)
    }

    @Test func init_createsQueueWhenItemsAreEmpty() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [Int](), selectedItem: 1)

        // ACT

        // ASSERT
        #expect(queue.currentItem == 1)
        #expect(queue.currentIndex == nil)
    }

    @Test func currentIndex_returnsIndexOfCurrentItem() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2)

        // ACT

        // ASSERT
        #expect(queue.currentIndex == 1)
    }

    @Test func currentIndex_setsCurrentItemWhenIndexIsValid() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1)

        // ACT
        queue.currentIndex = 2

        // ASSERT
        #expect(queue.currentItem == 3)
        #expect(queue.currentIndex == 2)
    }

    @Test func currentIndex_clearsCurrentItemWhenSetToNil() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2)

        // ACT
        queue.currentIndex = nil

        // ASSERT
        #expect(queue.currentItem == nil)
        #expect(queue.currentIndex == nil)
    }

    @Test func currentIndex_ignoresOutOfBoundsValues() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2)

        // ACT
        queue.currentIndex = -1

        // ASSERT
        #expect(queue.currentItem == 2)
        #expect(queue.currentIndex == 1)

        // ACT
        queue.currentIndex = 3

        // ASSERT
        #expect(queue.currentItem == 2)
        #expect(queue.currentIndex == 1)
    }

    @Test func has_returnsWhetherPreviousAndNextItemsExist() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2)

        // ACT

        // ASSERT
        #expect(queue.has(.previous))
        #expect(queue.has(.next))
    }

    @Test func has_returnsFalseForPreviousAtFirstItem() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1)

        // ACT

        // ASSERT
        #expect(!queue.has(.previous))
    }

    @Test func has_returnsFalseForNextAtLastItem() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 3)

        // ACT

        // ASSERT
        #expect(!queue.has(.next))
    }

    @Test func move_movesToPreviousItem() async throws {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2)

        // ACT
        try await queue.move(to: .previous)

        // ASSERT
        #expect(queue.currentItem == 1)
    }

    @Test func move_movesToNextItem() async throws {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 2)

        // ACT
        try await queue.move(to: .next)

        // ASSERT
        #expect(queue.currentItem == 3)
    }

    @Test func move_keepsCurrentItemWhenMovingPreviousFromFirstItem() async throws {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1)

        // ACT
        try await queue.move(to: .previous)

        // ASSERT
        #expect(queue.currentItem == 1)
    }

    @Test func move_keepsCurrentItemWhenMovingNextFromLastItem() async throws {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 3)

        // ACT
        try await queue.move(to: .next)

        // ASSERT
        #expect(queue.currentItem == 3)
    }

    @Test func move_selectsFirstItemWhenCurrentItemIsNil() async throws {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1)
        queue.currentIndex = nil

        // ACT
        try await queue.move(to: .next)

        // ASSERT
        #expect(queue.currentItem == 1)
    }

    @Test func moveToFirst_selectsFirstItem() {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 3)

        // ACT
        queue.moveToFirst()

        // ASSERT
        #expect(queue.currentItem == 1)
    }

    @Test func currentItemObservation_emitsUpdatedItemWhenCurrentIndexChanges() async throws {
        // ARRANGE
        let queue = StaticPlaybackQueue(items: [1, 2, 3], selectedItem: 1)
        var observedItem: Int?

        withObservationTracking {
            _ = queue.currentItem
        } onChangeAsync: { @MainActor in
                observedItem = queue.currentItem
        }

        // ACT
        queue.currentIndex = 1

        // ASSERT
        await busyWait { observedItem == 2 }
        #expect(observedItem == 2)
    }
}
