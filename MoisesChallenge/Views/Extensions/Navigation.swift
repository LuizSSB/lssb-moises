//
//  Navigation.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

extension View {
    func navigationDestination<T, Destination: View>(
        nonHashableItem: Binding<T?>,
        @ViewBuilder destination: @escaping (T) -> Destination
    ) -> some View {
        self.navigationDestination(
            isPresented: .init(
                get: { nonHashableItem.wrappedValue != nil },
                set: { _ in nonHashableItem.wrappedValue = nil}
            ),
            destination: {
                if let nonHashableItem = nonHashableItem.wrappedValue {
                    destination(nonHashableItem)
                }
            }
        )
    }
    
    func fullScreenCover<T, Destination: View>(
        nonHashableItem: Binding<T?>,
        @ViewBuilder content: @escaping (T) -> Destination
    ) -> some View {
        self.fullScreenCover(
            isPresented: .init(
                get: { nonHashableItem.wrappedValue != nil },
                set: { _ in nonHashableItem.wrappedValue = nil}
            ),
            content: {
                if let nonHashableItem = nonHashableItem.wrappedValue {
                    content(nonHashableItem)
                }
            }
        )
    }
    
}
