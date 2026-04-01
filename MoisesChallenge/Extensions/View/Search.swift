//
//  Search.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

struct SearchFocusHandlerModifier: ViewModifier {
    @Environment(\.isSearching) private var isSearching
    
    let onSearchFocused: (_ focused: Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isSearching) { _, searching in
                onSearchFocused(searching)
            }
    }
}
