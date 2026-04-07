//
//  CompleteSongPlayerScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

import SwiftUI

struct CompleteSongPlayerScreen: View {
    private enum Layout {
        static let sideListMinimumWidth: CGFloat = 650
        static let sideListPreferredWidthRatio: CGFloat = 0.34
        static let sideListMinWidth: CGFloat = 280
        static let sideListMaxWidth: CGFloat = 340
        static let sideListCornerRadius: CGFloat = 12
    }

    let viewModel: CompleteSongPlayerViewModel
    var showOptions = true
    var onMinimize: (() -> Void)?

    @State private var actionSheetSong: Song?
    @State private var isShowingSongListSheet = false

    var body: some View {
        GeometryReader { proxy in
            let showsInlineSongList = proxy.size.width >= Layout.sideListMinimumWidth

            HStack(spacing: 24) {
                playerSection

                if showsInlineSongList {
                    let songListWidth = min(
                        max(
                            proxy.size.width * Layout.sideListPreferredWidthRatio,
                            Layout.sideListMinWidth
                        ),
                        Layout.sideListMaxWidth
                    )

                    inlineSongList(width: songListWidth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationTitle(viewModel.actualPlayer.currentSong?.displayAlbumTitle ?? "-")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent(showsInlineSongList: showsInlineSongList)
            }
            .sheet(
                isPresented: Binding(
                    get: { !showsInlineSongList && isShowingSongListSheet },
                    set: { isShowingSongListSheet = $0 }
                )
            ) {
                NavigationStack {
                    songListContent(dismissAfterSelection: true)
                        .navigationTitle("Songs")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                viewModel.songList.loadFirstPageIfNeeded()
            }
            .onChange(of: showsInlineSongList) {
                if showsInlineSongList {
                    isShowingSongListSheet = false
                }
            }
            .songActionSheet(for: $actionSheetSong) { song, action in
                switch action {
                case .viewAlbum:
                    viewModel.selectAlbum(of: song)
                }
            }
        }
    }

    private var playerSection: some View {
        FocusedSongPlayerView(viewModel: viewModel.actualPlayer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func inlineSongList(width: CGFloat) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: Layout.sideListCornerRadius,
            style: .continuous
        )

        return songListContent(dismissAfterSelection: false)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .clipShape(shape)
            .glassEffect(.regular, in: shape)
            .frame(width: width)
            .frame(maxHeight: .infinity)
    }

    private func songListContent(dismissAfterSelection: Bool) -> some View {
        CompleteSongPlayerSongListView(
            playerViewModel: viewModel.actualPlayer,
            listViewModel: viewModel.songList
        ) { song in
            viewModel.select(song: song)
            if dismissAfterSelection {
                isShowingSongListSheet = false
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent(showsInlineSongList: Bool) -> some ToolbarContent {
        if let onMinimize {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onMinimize) {
                    Image(systemName: "chevron.down")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Minimize player")
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            if !showsInlineSongList {
                Button {
                    isShowingSongListSheet = true
                } label: {
                    Image(systemName: "music.note.list")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Song list")
            }

            if showOptions,
               let currentSong = viewModel.actualPlayer.currentSong
            {
                Button {
                    actionSheetSong = currentSong
                } label: {
                    Image(systemName: "ellipsis")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel(String(localized: .commonMoreOptions))
                .accessibilityHint(currentSong.displayTitle)
            }
        }
    }
}

private struct CompleteSongPlayerSongListView: View {
    @State var playerViewModel: any FocusedSongPlayerViewModel
    let listViewModel: any PaginatedListViewModel<Song>
    let onSelectSong: (Song) -> Void

    var body: some View {
        PaginatedListView(
            items: listViewModel.items,
            loadState: listViewModel.loadState,
            hasMore: listViewModel.hasMore,
            rowContent: songRow,
            placeholderContent: placeholderContent,
            loadNextPage: {
                listViewModel.loadNextPage()
            },
            refresh: {
                await listViewModel.refresh()
            },
            onError: listViewModel.interactWithError(shouldRetry:)
        )
    }

    @ViewBuilder
    private func songRow(_ song: Song) -> some View {
        Button {
            onSelectSong(song)
        } label: {
            HStack {
                SongRowView(song: song)

                if playerViewModel.currentSong?.id == song.id,
                   playerViewModel.playbackState == .playing
                {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .contentShape(Rectangle())
            .background {
                if playerViewModel.currentSong?.id == song.id {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.secondary.opacity(0.16))
                }
            }
        }
        .buttonStyle(.plain)
        .listRowInsets([.vertical], 0)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func placeholderContent(_ type: PaginatedListViewPlaceholderType) -> some View {
        switch type {
        case .idle:
            EmptyView()

        case .empty:
            ContentUnavailableView("No songs", systemImage: "music.note.list")

        case let .error(error):
            ContentUnavailableView {
                Label(error.title, systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button(String(localized: .commonTryAgain)) {
                    listViewModel.interactWithError(shouldRetry: true)
                }
            }
        }
    }
}
