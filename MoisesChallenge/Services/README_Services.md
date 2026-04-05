# Services

This directory contains the app's data-access layer.

Services are responsible for retrieving, caching, and persisting data, while staying ignorant of UI concerns. In this project they are modeled as lightweight `struct`s with async function properties, which makes them easy to compose, inject through the IoC container, and replace in tests without introducing protocol-heavy hierarchies.

## Role in the architecture

- Fetch domain data from external sources such as the iTunes API.
- Read and write cached data through SwiftData.
- Combine multiple data sources behind a single interface when appropriate.
- Expose a narrow API to view models and other higher-level consumers.

Most services in this directory follow the same pattern:

- A base service type defines the public operations.
- Concrete constructors create specific implementations, such as network-backed or cache-backed variants.
- A `hybrid` variant tries cache first and falls back to the network implementation.

## Directory structure

### `Song`

Song-related search services live in `Services/Song`.

- `SongSearchService.swift`: defines the song search service and its iTunes-backed implementation.
- `SongSearchService+Cache.swift`: defines a SwiftData-backed cache service for paginated song search results.
- `SongSearchService+Hybrid.swift`: combines cache and network behavior, returning cached results when possible and storing fresh ones after a network fetch.

One detail worth knowing: because the iTunes Search API does not support true offset-based pagination, the network-backed implementation fetches the full result set once and then serves slices of it to simulate paginated loading.

### `Album`

Album detail services live in `Services/Album`.

- `AlbumSearchService.swift`: defines the album lookup service and its iTunes-backed implementation.
- `AlbumSearchService+Cache.swift`: defines the SwiftData-backed cache for album details.
- `AlbumSearchService+Hybrid.swift`: composes the cache and network variants into the default album-loading behavior.

This keeps album lookup logic isolated from the view models that present album details.

### Root services and shared helpers

The files at the root of `Services` support multiple features:

- `InteractionService.swift`: persists and lists song playback interactions, and emits an event whenever a song is marked as played.
- `SwiftDataConfig.swift`: builds the app's shared `ModelContainer` and centralizes cache-related configuration such as TTL.
- `iTunesAPIConfig.swift`: stores the iTunes API endpoints and request defaults used by service implementations.
- `Alamofire.swift`: contains small Alamofire-specific helpers, such as normalizing request errors.

## Important components

### `SongSearchService`

The main service for song search.

- Returns `SongSearchPage` values built on the shared pagination models.
- Has clear implementation variants:
  - `iTunes` for live API data
  - `Cache` for SwiftData-backed retrieval
  - `hybrid` for cache-first behavior

### `AlbumSearchService`

The main service for loading album details.

- Fetches a single album by ID.
- Uses the same split between live, cached, and hybrid implementations as song search.

### `InteractionService`

Handles recently played song state.

- Stores a song interaction when playback occurs.
- Lists stored interactions using shared pagination primitives.
- Broadcasts `songMarkedPlayedEvent` so other parts of the app can react to recent-play updates.

## Important patterns

- Services return domain models such as `Song`, `Album`, and `SongInteraction`, not API or storage models.
- Cache implementations are intentionally separated from network implementations and composed at the service boundary.
- Shared configuration lives in this directory so service implementations do not duplicate endpoint or persistence setup.
- Except for emitted events, services are intentionally lightweight and mostly stateless, which keeps them easy to test and swap.
