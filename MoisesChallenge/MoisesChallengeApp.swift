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
    
    @State private var bottomContentHeight: CGFloat = 0
    
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
            .environment(\.rootBottomContentHeight, bottomContentHeight)
            .safeAreaInset(edge: .bottom) {
                if let miniPlayer = viewModel.miniPlayer {
                    MiniSongPlayerView(
                        viewModel: miniPlayer,
                        openPlayer: { viewModel.setCompletePlayer(presented: true) }
                    )
                    .overlay {
                        GeometryReader { reader in
                            Color.clear.onFirstAppear {
                                bottomContentHeight = reader.size.height
                            }
                        }
                    }
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
