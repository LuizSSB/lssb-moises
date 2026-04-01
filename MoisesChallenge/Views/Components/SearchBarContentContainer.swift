//
//  SearchBarContentContainer.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI

struct SearchBarContentContainer<Content: View>: View {
    @Environment(\.isSearching) private var isSearching
    
    let content: Content
    let onSearchStatusChanged: (_ enabled: Bool) -> Void
    
    var body: some View {
        content
            .onChange(of: isSearching) {
                onSearchStatusChanged($1)
            }
    }
}

extension SearchBarContentContainer {
    init(
        @ViewBuilder content: () -> Content,
        onSearchStatusChanged: @escaping (_ enabled: Bool) -> Void
    ) {
        self.init(content: content(), onSearchStatusChanged: onSearchStatusChanged)
    }
}
