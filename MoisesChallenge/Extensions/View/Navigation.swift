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
    
    func navigationDestination<T, Destination: View>(
        presentationViewModel: any PresentationViewModel<T>,
        @ViewBuilder destination: @escaping (T) -> Destination
    ) -> some View {
        self.navigationDestination(
            nonHashableItem: .init(
                get: { presentationViewModel.presented },
                set: { _ in presentationViewModel.dismiss() }
            ),
            destination: destination
        )
    }
}
