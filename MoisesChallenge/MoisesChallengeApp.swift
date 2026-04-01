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
    
    private let songsListViewModel = SongsListViewModel(
        dataSource: SongDataSource(),
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SongsListScreen(viewModel: songsListViewModel) { song in
                    // TODO: Navigate to PlayerView (Feature 2)
                    print("Selected: \(song.title)")
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
