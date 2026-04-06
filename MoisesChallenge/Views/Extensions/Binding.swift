//
//  Binding.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

import SwiftUI

private struct SendableKeyPath<Root, Value>: @unchecked Sendable {
    let keyPath: ReferenceWritableKeyPath<Root, Value>
}

extension Binding where Value: Sendable {
    init<Source: Sendable>(from source: Source, to field: ReferenceWritableKeyPath<Source, Value>) {
        let sendable = SendableKeyPath(keyPath: field)
        self.init(
            get: { source[keyPath: sendable.keyPath] },
            set: { source[keyPath: sendable.keyPath] = $0 }
        )
    }
}
