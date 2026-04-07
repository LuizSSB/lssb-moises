//
//  TestUtils.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 04/04/26.
//

import Testing

func busyWait(
    timeoutIterations: Int = 200,
    until condition: @escaping @MainActor () -> Bool
) async {
    for _ in 0 ..< timeoutIterations {
        if await condition() {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }

    Issue.record("Timed out waiting for condition.")
}

func busyWaitAsync(
    timeoutIterations: Int = 200,
    intervalBetweenChecks: Duration = .milliseconds(10),
    until condition: @escaping @Sendable () async -> Bool
) async {
    for _ in 0 ..< timeoutIterations {
        if await condition() {
            return
        }
        try? await Task.sleep(for: intervalBetweenChecks)
    }

    Issue.record("Timed out waiting for async condition.")
}
