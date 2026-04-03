//
//  PaginatedListView.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI

enum PaginatedListViewPlaceholderType {
    case idle,
         empty,
         error(String)
}

struct PaginatedListView<
    Item: Identifiable & Sendable,
    RowContent: View,
    PlaceholderContent: View
>: View {
    
    let items: [Item]
    let loadState: PaginatedListLoadState
    let hasMore: Bool
    @ViewBuilder var rowContent: (Item) -> RowContent
    @ViewBuilder var placeholderContent: (PaginatedListViewPlaceholderType) -> PlaceholderContent
    var loadNextPage: () -> Void
    var refresh: @Sendable () async -> Void

    var body: some View {
        switch loadState {
        case .loadingFirstPage:
            Text("Loading...")
            
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            placeholderContent(.empty)

        case .error(let message):
            placeholderContent(.error(message))

        default:
            if loadState == .idle {
                placeholderContent(.idle)
            } else {
                List {
                    ForEach(items) { item in
                        rowContent(item)
                    }
                    
                    if hasMore && loadState != .loadingNextPage {
                        Color.clear
                            .frame(height: 1)
                            .onAppear(perform: loadNextPage)
                    }
                    
                    if loadState == .loadingNextPage {
                        Text("Loading more...")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable(action: refresh)
            }
        }
    }
}
