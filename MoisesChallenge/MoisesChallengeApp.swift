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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var songListViewModel = SongListViewModel(
        dataSource: SongDataSource(),
    )

    var body: some Scene {
        let bindable = Bindable(songListViewModel)
        WindowGroup {
            NavigationStack {
                SongListScreen(viewModel: songListViewModel) { song in
                    // TODO: Navigate to PlayerView (Feature 2)
                    print("Selected: \(song.title)")
                }
                .navigationDestination(item: $songListViewModel.player) { _ in
//                    SongPlayerScreen(
//                        viewModel: PlayerViewModel(queue: songListViewModel)
//                    )
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
