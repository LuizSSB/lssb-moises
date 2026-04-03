//
//  MoisesChallengeApp.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI
import SwiftData

@main
struct MoisesChallengeApp: App {
    @State private var songListViewModel: any SongListViewModel = SongListViewModelImpl(
        interactionService: InteractionService.swiftData,
        songService: SongSearchService.hybrid,
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SongListScreen(viewModel: songListViewModel)
            }
        }
    }
}
