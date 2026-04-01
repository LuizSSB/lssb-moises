//
//  AlbumScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

struct AlbumScreen: View {
    @State var viewModel: AlbumViewModel
    
    var body: some View {
        switch viewModel.album {
        case .none, .running, .success:
            let album = viewModel.album.result
            ScrollView {
                VStack {
                    ArtworkView(artworkURL: album?.mainArtworkURL)
                        .overlay {
                            if case .running = viewModel.album {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.black.opacity(0.125))
                            }
                        }
                    
                    Text(album?.displayTitle ?? "-")
                        .font(.system(size: 24))
                    
                    Text(album?.displayArtistName ?? "-")
                        .font(.system(size: 17))
                    
                    ForEach(album?.songs ?? []) { song in
                        Button {
                            viewModel.onSelect(song: song)
                        } label: {
                            SongRowView(song: song)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .onAppear {
                viewModel.onAppear()
            }
            .navigationDestination(presentationViewModel: viewModel.player) {
                SongPlayerScreen(viewModel: $0, showsOptions: false)
            }
        case .failure(let error):
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        }
    }
}
