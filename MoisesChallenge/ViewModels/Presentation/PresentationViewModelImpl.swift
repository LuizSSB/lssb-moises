//
//  PresentationViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Observation

@MainActor
@Observable
class PresentationViewModelImpl<T>: PresentationViewModel {
    // MARK: - Public State

    private(set) var presented: T?

    // MARK: - Actions

    func present(_ value: T) {
        presented = value
    }

    func dismiss() {
        presented = nil
    }
}
