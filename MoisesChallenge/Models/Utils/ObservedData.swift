//
//  ObservedData.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

import Foundation

struct ObservedData<T: Equatable & Hashable & Sendable>: Equatable, Sendable, Hashable {
    let id = UUID()
    let value: T
}
