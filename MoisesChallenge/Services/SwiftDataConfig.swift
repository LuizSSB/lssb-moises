//
//  SwiftDataConfig.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Foundation
import SwiftData

private func makeAppModelContainer() -> ModelContainer {
    let schema = Schema([
        SongInteractionSwiftData.self,
        CachedAlbumSwiftData.self,
        CachedSongSearchPageSwiftData.self
    ])
    let applicationSupportURL = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
    ).first!
    try? FileManager.default.createDirectory(
        at: applicationSupportURL,
        withIntermediateDirectories: true
    )
    let storeURL = applicationSupportURL.appendingPathComponent("default.store")
    
    func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: config)
    }
    
    do {
        return try makeContainer()
    } catch {
        let sidecarURLs = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]
        sidecarURLs.forEach { try? FileManager.default.removeItem(at: $0) }
        
        do {
            return try makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

let swiftDataConfig = (
    appModelContainer: makeAppModelContainer(),
    cacheTTL: TimeInterval(60 * 60 * 24) // 1 day
)
