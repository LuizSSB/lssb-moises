//
//  Event.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation

actor Event<T: Sendable> {
    private var continuations: [UUID: AsyncStream<T>.Continuation] = [:]
    
    var observerCount: Int {
        continuations.count
    }
    
    func stream() -> (id: UUID, stream: AsyncStream<T>) {
        let id = UUID()
        
        return (
            id,
            AsyncStream { continuation in
                continuations[id] = continuation
                
                continuation.onTermination = { [weak self] _ in
                    guard let self else { return }
                    Task {
                        await self.removeContinuation(id)
                    }
                }
            }
        )
    }
    
    // Technically, leaving emit public-like like this isn't good, as anyone with a reference to the Event could post a message, but we are all adults here and we don't do that.
    func emit(_ value: T) {
        for continuation in continuations.values {
            continuation.yield(value)
        }
    }
    
    nonisolated func emitAndForget(_ value: T) {
        Task {
            await emit(value)
        }
    }
    
    func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
