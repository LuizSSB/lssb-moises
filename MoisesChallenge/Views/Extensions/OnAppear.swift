//
//  OnAppear.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 19/04/25.
//

import SwiftUI

private struct OnFirstAppearWrapper<Content: View>: View {
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

private struct FirstTaskWrapper<Content: View>: View {
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

struct EnsureRerenderOnAppearWrapper<Content: View>: View {
    let content: Content

    @State var id = UUID()

    var body: some View {
        content
            .id(id)
            .onDisappear {
                id = UUID()
            }
    }
}

extension View {
    func onFirstAppear(action: @escaping () -> Void) -> some View {
        OnFirstAppearWrapper(content: self, action: action)
    }

    func firstTask(action: @escaping () async throws -> Void) -> some View {
        FirstTaskWrapper(content: self, action: action)
    }

    func ensureRerenderOnAppear() -> some View {
        EnsureRerenderOnAppearWrapper(content: self)
    }
}
