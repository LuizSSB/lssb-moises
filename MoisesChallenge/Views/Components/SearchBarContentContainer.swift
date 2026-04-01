//
//  SearchBarContentContainer.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI

struct SearchBarContentContainer: View {
    @Environment(\.isSearching) private var isSearching
    
    let content: any View
    let onSearchStatusChanged: (_ enabled: Bool) -> Void
    
    var body: some View {
        AnyView(content)
            .onChange(of: isSearching) {
                onSearchStatusChanged($1)
            }
    }
}

extension SearchBarContentContainer {
    init(
        @ViewBuilder content: () -> any View,
        onSearchStatusChanged: @escaping (_ enabled: Bool) -> Void
    ) {
        self.init(content: content(), onSearchStatusChanged: onSearchStatusChanged)
    }
}
