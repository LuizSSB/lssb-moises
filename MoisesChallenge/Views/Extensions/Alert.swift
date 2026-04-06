//
//  Alert.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 21/04/25.
//

import SwiftUI

extension View {
    func alert<T>(
        presenting: Binding<T?>,
        title: (T) -> String,
        @ViewBuilder message: (T) -> any View = { _ in EmptyView() },
        @ViewBuilder actions: (T) -> any View = { _ in EmptyView() }
    ) -> some View {
        self.alert(
            {
                if let presented = presenting.wrappedValue {
                    return title(presented)
                }
                return ""
            }(),
            isPresented: .init(
                get: { presenting.wrappedValue != nil },
                set: { _ in presenting.wrappedValue = nil }
            ),
            actions: {
                if let presented = presenting.wrappedValue {
                    AnyView(actions(presented))
                }
            },
            message: {
                if let presented = presenting.wrappedValue {
                    AnyView(message(presented))
                }
            }
        )
    }
}
