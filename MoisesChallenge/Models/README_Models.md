# Models

This directory contains the main data types used throughout the app.

At a high level, the `Models` layer defines:

- The app's domain entities, such as songs and albums.
- API-facing types used to decode iTunes responses.
- SwiftData storage models used for caching.
- Shared utility types for pagination, loading state, and user-facing errors.

These models are intentionally grouped by purpose so each layer of the app can depend on the right representation for the job without mixing concerns.

## Directory structure

### Root models

The files at the root of `Models` define the business-level entities used across the app:

- `Song.swift`: the main song entity shown in lists and played in the player.
- `Album.swift`: album metadata plus an optional song list when album tracks have been loaded.
- `Artist.swift`: lightweight artist identity used by songs and albums.
- `SongInteraction.swift`: records user interaction with a song, currently focused on recent playback.
- `Playback.swift`: shared playback enums such as queue direction, repeat mode, and playback state.

These are the types most other layers should prefer to work with.

### `API`

Types in `Models/API` exist to describe external API payloads and translate them into domain models.

- `iTunes.swift`: defines `ITunesAPIResponse`, the app's decoding model for iTunes API responses.
- `iTunes+Song.swift`: maps iTunes response entries into `Song`.
- `iTunes+Album.swift`: maps iTunes response data into `Album`, including album track lists when available.
- `SongSearchParams.swift`: describes song search input and defines the pagination aliases used by song search flows.

This separation keeps service code from leaking raw API structures into the rest of the app.

### `Storage`

Types in `Models/Storage` are the SwiftData representations used for caching and persistence.

- `CachedSongSwiftData.swift`: stores song data in a form suitable for SwiftData and converts it back into `Song`.
- `CachedAlbumSwiftData.swift`: stores album metadata, cached tracks, and cache timestamps.
- `CachedSongSearchPageSwiftData.swift`: stores paginated search results keyed by search term and pagination values.
- `SongInteractionSwiftData.swift`: stores recently played song interactions.

These types are intentionally separate from the root domain models so persistence concerns stay isolated from business logic.

### `Utils`

Types in `Models/Utils` are shared supporting models used across multiple features.

- `Pagination.swift`: generic pagination primitives, paginated page values, and paginated list load state.
- `ActionStatus.swift`: generic action-state enum for operations that can be idle, running, successful, or failed.
- `Error.swift`: app-specific error types and `UserFacingError`, which packages errors into UI-friendly content.

## Important patterns

- Domain models are plain value types and are easy to pass between layers.
- API and storage models map into domain models instead of becoming the domain models.
- Shared enums such as playback state and pagination state live here because they are used by more than one feature.
- The split between root, `API`, `Storage`, and `Utils` helps preserve MVVM boundaries and keeps service-specific concerns out of views and view models.
