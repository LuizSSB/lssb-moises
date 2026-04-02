//
//  MoisesChallengeApp.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI
import SwiftData
import FactoryKit

@main
struct MoisesChallengeApp: App {
    @State private var songListViewModel = SongListViewModel(
        interactionService: InteractionService.swiftData(),
        songService: SongSearchService.iTunes,
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SongListScreen(viewModel: songListViewModel)
            }
        }
    }
}
