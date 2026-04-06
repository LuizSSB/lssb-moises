//
//  MoisesChallengeApp.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI
import Observation


@main
struct MoisesChallengeApp: App {
    private var viewModel: any AppViewModel
    
    init() {
        let container = LiveIoCContainer()
        self.viewModel = AppViewModelImpl(container: container)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SongListScreen(viewModel: viewModel.songList)
                    .navigationDestination(
                        nonHashableItem: .init(from: viewModel, to: \.album),
                        destination: AlbumScreen.init(viewModel:)
                    )
            }
            .safeAreaInset(edge: .bottom) {
                if let miniPlayer = viewModel.miniPlayer {
                    MiniSongPlayerView(
                        viewModel: miniPlayer,
                        openPlayer: { viewModel.setCompletePlayer(presented: true) }
                    )
                }
            }
            .onFirstAppear {
                viewModel.setup()
            }
            .fullScreenCover(nonHashableItem: .constant(viewModel.completePlayer)) { player in
                NavigationStack {
                    CompleteSongPlayerScreen(
                        viewModel: player,
                        onMinimize: { viewModel.setCompletePlayer(presented: false) }
                    )
                }
            }
            
        }
    }
}
