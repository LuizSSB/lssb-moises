//
//  View.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 19/04/25.
//

import SwiftUI

struct OnFirstAppearModifier: ViewModifier {
    private struct WrapperView: View {
        let content: Content
        let action: () -> Void
        
        @State var appeared = false
        
        var body: some View {
            content
                .onAppear {
                    if !appeared {
                        appeared = true
                        action()
                    }
                }
        }
    }
    
    let action: () -> Void
    
    func body(content: Content) -> some View {
        WrapperView(content: content, action: action)
    }
}

struct FirstTaskModifier: ViewModifier {
    private struct WrapperView: View {
        let content: Content
        let action: () async throws -> Void
        
        @State var appeared = false
        
        var body: some View {
            content
                .task {
                    if !appeared {
                        appeared = true
                        try? await action()
                    }
                }
        }
    }
    
    let action: () async throws -> Void
    
    func body(content: Content) -> some View {
        WrapperView(content: content, action: action)
    }
}

extension View {
    func onFirstAppear(action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }
    func firstTask(action: @escaping () async throws -> Void) -> some View {
        modifier(FirstTaskModifier(action: action))
    }
}
