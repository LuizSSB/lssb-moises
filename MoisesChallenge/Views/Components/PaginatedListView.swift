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
    private let topScrollId = "paginated-list-top"
    
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
            ProgressView()
                .ensureRerenderOnAppear()

        case .empty:
            placeholderContent(.empty)

        case .error(let error) where items.isEmpty:
            placeholderContent(.error(error))

        default:
            if loadState == .idle {
                placeholderContent(.idle)
            } else {
                ScrollViewReader { proxy in
                    List {
                        if case .refreshing = loadState {
                            ProgressView()
                                .ensureRerenderOnAppear()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .listRowSeparator(.hidden)
                        }
                        
                        ForEach(Array(items.enumerated()), id: \.element.id) { offset, element in
                            let row = rowContent(element)
                            if offset == 0 {
                                row
                                    .id(topScrollId)
                            } else {
                                row
                            }
                        }
                        
                        if hasMore && loadState != .loadingNextPage {
                            Color.clear
                                .frame(height: 1)
                                .onAppear(perform: loadNextPage)
                                .listRowSeparator(.hidden)
                        }
                        
                        if loadState == .loadingNextPage {
                            ProgressView()
                                .ensureRerenderOnAppear()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable(action: refresh)
                    .onChange(of: loadState) {
                        if loadState == .refreshing {
                            withAnimation {
                                proxy.scrollTo(topScrollId, anchor: .top)
                            }
                        }
                    }
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
                            Button(String(localized: .commonTryAgain)) {
                                onError(true)
                            }
                            
                            Button(String(localized: .commonDismiss), role: .cancel) {
                                onError(false)
                            }
                        }
                    )
                }
            }
        }
    }
}
