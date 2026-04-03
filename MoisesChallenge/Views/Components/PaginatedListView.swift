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
         error(UserFacingError)
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
    var onError: (_ shouldRetry: Bool) -> Void

    var body: some View {
        switch loadState {
        case .loadingFirstPage:
            Text("Loading...")
            
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            placeholderContent(.empty)

        case .error(let error) where items.isEmpty:
            placeholderContent(.error(error))

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
                .alert(
                    presenting: .constant({
                        if case let .error(data) = loadState {
                            return data
                        }
                        return nil
                    }()),
                    title: \.title,
                    message: { Text($0.message) },
                    actions: { _ in
                        Button("Try Again") {
                            onError(true)
                        }
                        
                        Button("Dismiss", role: .cancel) {
                            onError(false)
                        }
                    }
                )
            }
        }
    }
}
