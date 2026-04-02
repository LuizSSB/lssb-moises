//
//  SwiftDataConfig.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import SwiftData

let appModelContainer: ModelContainer = {
    let schema = Schema([
        SongInteractionSwiftData.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
        return try ModelContainer(for: schema, configurations: config)
    } catch {
        // A failed container is unrecoverable — crash loudly in development.
        fatalError("Failed to create ModelContainer: \(error)")
    }
}()
