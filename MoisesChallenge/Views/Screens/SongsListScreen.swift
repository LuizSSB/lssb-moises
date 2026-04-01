//
//  SongsListScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI

struct SongsListScreen: View {
    @State var viewModel: SongsListViewModel
    var onSongSelected: (Song) -> Void = { _ in }

    var body: some View {
        SearchBarContentContainer {
            if let searchList = viewModel.searchList {
                PaginatedListView(
                    items: searchList.items,
                    loadState: searchList.loadState,
                    hasMore: !(searchList.latestResult?.reachedEnd ?? true)
                ) { song in
                    Button {
                        onSongSelected(song)
                    } label: {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                } placeholderContent: {
                    searchPromptView
                } loadNextPage: {
                    searchList.loadNextPage()
                } refresh: {
                    await searchList.refresh()
                }
            } else {
                let recentList = viewModel.recentList
                PaginatedListView(
                    items: recentList.items,
                    loadState: recentList.loadState,
                    hasMore: !(recentList.latestResult?.reachedEnd ?? true)
                ) { song in
                    Button {
                        onSongSelected(song)
                    } label: {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                } placeholderContent: {
                    EmptyView()
                } loadNextPage: {
                    recentList.loadNextPage()
                } refresh: {
                    await recentList.refresh()
                }
            }
        } onSearchStatusChanged: {
            viewModel.onSearchBar(focused: $0)
        }
        .navigationTitle("Songs")
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always)
        )
        .onSubmit(of: .search) {
            viewModel.onSearchSubmitted()
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var searchPromptView: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Search on iTunes")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}
