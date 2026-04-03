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
                items: currentList.items as! [Song],
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
                onError: currentList.onInteractionWithError(shouldRetry:)
            )
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
        .songActionSheet(for: $actionSheetSong) { song, action in
            switch action {
            case .viewAlbum:
                viewModel.onSelectAlbum(of: song)
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
                viewModel.onSelect(song: song)
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
                Text("Search on iTunes")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
        case (.empty, .some):
            ContentUnavailableView(
                "No results found for '\(viewModel.currentQuery)'",
                systemImage: "music.note.list"
            )
            
        case (.empty, nil):
            ContentUnavailableView(
                "No recently played songs",
                systemImage: "music.note.list",
                description: Text("Try the search bar above to look for your favorite artist or something")
            )
            
        case let (.error(error), _):
            ContentUnavailableView {
                Label(error.title, systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button("Try Again") {
                    viewModel.currentList.onInteractionWithError(shouldRetry: true)
                }
            }
        }
    }
}
