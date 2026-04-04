//
//  EventTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 03/04/26.
//

import Testing
@testable import MoisesChallenge

struct EventTests {

    @Test func stream_returnsDistinctIds() async {
        let event = Event<Int>()
        let (id1, _) = await event.stream()
        let (id2, _) = await event.stream()
        #expect(id1 != id2)
    }

    @Test func emit_deliversValueToSingleSubscriber() async {
        let event = Event<Int>()
        let (_, stream) = await event.stream()

        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        await event.emit(42)
        let value = await reader.value
        #expect(value == 42)
    }

    @Test func emit_broadcastsToAllSubscribers() async {
        let event = Event<Int>()
        let (_, stream1) = await event.stream()
        let (_, stream2) = await event.stream()

        let reader1 = Task {
            var iterator = stream1.makeAsyncIterator()
            return await iterator.next()
        }
        let reader2 = Task {
            var iterator = stream2.makeAsyncIterator()
            return await iterator.next()
        }

        await event.emit(7)

        #expect(await reader1.value == 7)
        #expect(await reader2.value == 7)
    }

    @Test func emit_deliversMultipleValuesInOrder() async {
        let event = Event<Int>()
        let (_, stream) = await event.stream()

        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            var values: [Int] = []
            for _ in 0..<3 {
                if let v = await iterator.next() {
                    values.append(v)
                }
            }
            return values
        }

        await event.emit(1)
        await event.emit(2)
        await event.emit(3)

        let values = await reader.value
        #expect(values == [1, 2, 3])
    }

    @Test func emitAndForget_deliversValue() async {
        let event = Event<String>()
        let (_, stream) = await event.stream()

        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        event.emitAndForget("done")

        let value = await reader.value
        #expect(value == "done")
    }

    @Test func removeContinuation_excludesThatStreamFromEmits() async {
        let event = Event<Int>()
        let (removedId, _) = await event.stream()
        let (_, stream2) = await event.stream()

        await event.removeContinuation(removedId)

        let reader = Task {
            var iterator = stream2.makeAsyncIterator()
            return await iterator.next()
        }

        await event.emit(3)
        #expect(await reader.value == 3)
    }
}
