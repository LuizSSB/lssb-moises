//
//  Observation.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

import Observation

func withObservationTracking<T>(_ apply: () -> T, onChangeAsync: @Sendable @escaping () async -> Void) -> T {
    withObservationTracking(apply, onChange: {
        Task {
            await onChangeAsync()
        }
    })
}
