import Foundation
import SwiftData
@testable import MoisesChallenge

func makeTestModelContainer() throws -> ModelContainer {
    let schema = Schema([
        SongInteractionSwiftData.self,
        CachedAlbumSwiftData.self,
        CachedSongSearchPageSwiftData.self
    ])
    let storeURL = URL.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("store")
    let configuration = ModelConfiguration(schema: schema, url: storeURL)
    return try ModelContainer(for: schema, configurations: configuration)
}
