//
//  SongListScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI

struct SongListScreen: View {
    @State var viewModel: SongListViewModel
    
    var body: some View {
        List {
            if viewModel.state.isLoadingFirstBatch {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
            }
            
            if let songs = viewModel.state.songs {
                ForEach(Array(songs.enumerated()), id: \.1.id) { offset, song in
                    listSong(offset, song)
                }
            } else if viewModel.state.songsFetchStatus != .running {
                Text("Pull to refresh")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
            }
            
            if viewModel.state.isLoadingMore {
                Text("Loading...")
                    .fontWeight(.ultraLight)
                    .fontWidth(.expanded)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle("Songs")
        .toolbar {
        }
        .firstTask {
            await viewModel.refresh()
        }
        .alert(
            presenting: .constant({
                if case let .failure(error) = viewModel.state.songsFetchStatus {
                    return error
                }
                return nil
            }()),
            title: { _ in "Failure" },
            message: { error in Text(error) },
            actions: { _ in
                Button("Dismiss") {
                    viewModel.abandonLoading()
                }
            }
        )
    }
    
    @ViewBuilder func listSong(_ offset: Int, _ song: Song) -> some View {
        Button {
            viewModel.select(song)
        } label: {
            HStack {
                Text(song.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            if offset == (viewModel.state.songs?.count ?? 0) - 1 {
                viewModel.loadMore()
            }
        }
    }
}

#Preview {
    NavigationStack {
//        SongListScreen(viewModel: .init())
        Text("asd")
    }
}
