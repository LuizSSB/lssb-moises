import Foundation
@testable import MoisesChallenge
import SwiftData

func makeTestModelContainer() throws -> ModelContainer {
    let schema = Schema([
        CachedSongSwiftData.self,
        SongInteractionSwiftData.self,
        CachedAlbumSwiftData.self,
        CachedSongSearchPageSwiftData.self,
    ])
    let storeURL = URL.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("store")
    let configuration = ModelConfiguration(schema: schema, url: storeURL)
    return try ModelContainer(for: schema, configurations: configuration)
}
