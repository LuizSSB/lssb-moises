//
//  ButtonStyle.swift
//  MoisesChallenge
//
//  Created by Codex on 03/04/26.
//

import SwiftUI

struct AdaptivePlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == AdaptivePlainButtonStyle {
    static var adaptivePlain: AdaptivePlainButtonStyle { .init() }
}
