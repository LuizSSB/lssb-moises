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
    private let container = LiveIoCContainer()
    @State private var songListViewModel: any SongListViewModel

    init() {
        let container = LiveIoCContainer()
        self._songListViewModel = State(initialValue: container.songListViewModel())
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SongListScreen(viewModel: songListViewModel)
            }
        }
    }
}
