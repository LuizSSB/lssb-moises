//
//  AlbumScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

struct AlbumScreen: View {
    @State var viewModel: any AlbumViewModel
    
    var body: some View {
        switch viewModel.album {
        case .none, .running, .success:
            let album = viewModel.album.result
            ScrollView {
                VStack(spacing: 0) {
                    ArtworkView(artworkURL: album?.mainArtworkURL) {
                        if album == nil || $0?.isFinished == false {
                            ProgressView()
                        } else {
                            ArtworkViewDefaultPlaceholderContent()
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.bottom, 16)
                    .accessibilityHidden(true)
                    
                    Text(album?.displayTitle ?? "-")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(album?.displayArtistName ?? "-")
                        .font(.subheadline)
                        .padding(.bottom, 40)
                    
                    ForEach(album?.songs ?? []) { song in
                        Button {
                            viewModel.onSelect(song: song)
                        } label: {
                            SongRowView(song: song)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 7)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .navigationDestination(presentationViewModel: viewModel.player) {
                SongPlayerScreen(viewModel: $0, showsOptions: false)
            }
        case .failure(let error):
            ContentUnavailableView {
                Label(error.title, systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button(String(localized: .commonTryAgain)) {
                    viewModel.loadAlbum()
                }
            }
        }
    }
}
