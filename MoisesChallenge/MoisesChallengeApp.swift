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
                    .navigationDestination(presentationViewModel: viewModel.album) {
                        AlbumScreen(viewModel: $0)
                    }
            }
            .safeAreaInset(edge: .bottom) {
                if let currentPlayer = viewModel.innerPlayer {
                    MiniSongPlayerView(
                        viewModel: currentPlayer.actualPlayer,
                        openPlayer: { viewModel.setPlayer(presented: true) }
                    )
                }
            }
            .onFirstAppear {
                viewModel.setup()
            }
            .fullScreenCover(presentationViewModel: viewModel.player) { player in
                NavigationStack {
                    CompleteSongPlayerScreen(
                        viewModel: player,
                        onMinimize: { viewModel.setPlayer(presented: false) }
                    )
                }
            }
            
        }
    }
}
