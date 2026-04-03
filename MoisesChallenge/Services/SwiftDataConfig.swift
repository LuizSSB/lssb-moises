//
//  SwiftDataConfig.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

let swiftDataConfig = (
    appModelContainer: {
        let schema = Schema([
            SongInteractionSwiftData.self,
            CachedAlbumSwiftData.self,
            CachedSongSearchPageSwiftData.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }(),
    cacheTTL: TimeInterval(60 * 60 * 24) // 1 day
)
