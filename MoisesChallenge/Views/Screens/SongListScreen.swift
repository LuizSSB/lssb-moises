//
//  SongListScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI

struct SongListScreen: View {
    @State var viewModel: any SongListViewModel
    
    @State private var actionSheetSong: Song?
    
    var body: some View {
        SearchBarContentContainer {
            let currentList = viewModel.currentList
            PaginatedListView(
                items: currentList.items,
                loadState: currentList.loadState,
                hasMore: currentList.hasMore,
                rowContent: songRow,
                placeholderContent: placeholderContent,
                loadNextPage: {
                    currentList.loadNextPage()
                },
                refresh: {
                    await currentList.refresh()
                },
                onError: currentList.interactWithError(shouldRetry:)
            )
        } onSearchStatusChanged: {
            viewModel.handleSearchBar(focused: $0)
        }
        .navigationTitle(String(localized: .songsNavigationTitle))
        .searchable(
            text: $viewModel.workingSearchQuery,
            placement: .navigationBarDrawer(displayMode: .always)
        )
        .onSubmit(of: .search) {
            viewModel.submitSearch()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .songActionSheet(for: $actionSheetSong) { song, action in
            switch action {
            case .viewAlbum:
                viewModel.selectAlbum(of: song)
            }
        }
        .navigationDestination(presentationViewModel: viewModel.player) {
            SongPlayerScreen(viewModel: $0)
        }
        .navigationDestination(presentationViewModel: viewModel.album) {
            AlbumScreen(viewModel: $0)
        }
    }
    
    @ViewBuilder func songRow(_ song: Song) -> some View {
        HStack {
            Button {
                viewModel.select(song: song)
            } label: {
                SongRowView(song: song)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if song.album != nil {
                Button {
                    actionSheetSong = song
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: .commonMoreOptions))
                .accessibilityHint(song.displayTitle)
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets([.vertical], 7)
    }
    
    @ViewBuilder func placeholderContent(_ type: PaginatedListViewPlaceholderType) -> some View {
        switch (type, viewModel.searchList) {
        case (.idle, nil):
            EmptyView()
            
        case (.idle, .some):
            VStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(String(localized: .songsPlaceholderSearch))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            
        case (.empty, .some):
            ContentUnavailableView(
                String(localized: .songsEmptySearchResults(viewModel.currentQuery)),
                systemImage: "music.note.list"
            )
            
        case (.empty, nil):
            ContentUnavailableView(
                String(localized: .songsEmptyRecentTitle),
                systemImage: "music.note.list",
                description: Text(String(localized: .songsEmptyRecentDescription))
            )
            
        case let (.error(error), _):
            ContentUnavailableView {
                Label(error.title, systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button(String(localized: .commonTryAgain)) {
                    viewModel.currentList.interactWithError(shouldRetry: true)
                }
            }
        }
    }
}
