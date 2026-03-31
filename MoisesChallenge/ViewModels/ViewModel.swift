//
//  ViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 18/04/25.
//

import Foundation
import SwiftUI

protocol ViewModelState: Equatable, Hashable {
}

@MainActor protocol ViewModel: Observable, AnyObject {
    associatedtype State: ViewModelState
    var state: State { get }
}

extension ViewModel {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.state == rhs.state
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(state)
    }
}

extension ViewModel {
    @MainActor
    func update(
        animation: Animation? = .default,
        action: @escaping () -> Void
    ) -> Void {
        if let animation {
            withAnimation(animation, action)
        } else {
            action()
        }
    }
}
