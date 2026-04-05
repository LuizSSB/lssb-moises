//
//  CompleteSongPlayerScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

import SwiftUI

struct CompleteSongPlayerScreen: View {
    @State var viewModel: CompleteSongPlayerViewModel
    var showOptions = true
    
    @State private var actionSheetSong: Song?
    
    var body: some View {
        FocusedSongPlayerView(viewModel: viewModel.actualPlayer)
            .frame(maxHeight: .infinity)
            .padding(24)
            .navigationTitle(viewModel.actualPlayer.currentSong?.displayAlbumTitle ?? "-")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if showOptions,
                       let currentSong = viewModel.actualPlayer.currentSong{
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
            .songActionSheet(for: $actionSheetSong) { song, action in
                switch action {
                case .viewAlbum:
                    viewModel.selectAlbum(of: song)
                }
            }
            .navigationDestination(presentationViewModel: viewModel.album) {
                AlbumScreen(viewModel: $0)
            }
    }
}
