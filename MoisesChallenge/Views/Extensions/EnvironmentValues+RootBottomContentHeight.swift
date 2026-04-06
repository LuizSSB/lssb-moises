//
//  EnvironmentValues+RootBottomContentHeight.swift
//  MoisesChallenge
//
//  Created by Codex on 06/04/26.
//

import SwiftUI

private struct RootBottomContentHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var rootBottomContentHeight: CGFloat {
        get { self[RootBottomContentHeightKey.self] }
        set { self[RootBottomContentHeightKey.self] = newValue }
    }
}
