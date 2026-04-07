//
//  Navigation.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

extension View {
    func navigationDestination<T>(
        nonHashableItem: Binding<T?>,
        @ViewBuilder destination: @escaping (T) -> some View
    ) -> some View {
        navigationDestination(
            isPresented: .init(
                get: { nonHashableItem.wrappedValue != nil },
                set: { _ in nonHashableItem.wrappedValue = nil }
            ),
            destination: {
                if let nonHashableItem = nonHashableItem.wrappedValue {
                    destination(nonHashableItem)
                }
            }
        )
    }

    func fullScreenCover<T>(
        nonHashableItem: Binding<T?>,
        @ViewBuilder content: @escaping (T) -> some View
    ) -> some View {
        fullScreenCover(
            isPresented: .init(
                get: { nonHashableItem.wrappedValue != nil },
                set: { _ in nonHashableItem.wrappedValue = nil }
            ),
            content: {
                if let nonHashableItem = nonHashableItem.wrappedValue {
                    content(nonHashableItem)
                }
            }
        )
    }
}
