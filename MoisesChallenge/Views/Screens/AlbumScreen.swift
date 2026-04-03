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
                VStack {
                    ArtworkView(artworkURL: album?.mainArtworkURL)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
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
            ContentUnavailableView {
                Label(error.title, systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button("Try Again") {
                    viewModel.loadAlbum()
                }
            }
        }
    }
}
