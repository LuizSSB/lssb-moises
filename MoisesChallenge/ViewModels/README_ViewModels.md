# ViewModels

This directory contains the app's View Model layer.

View models are the main coordinators of business logic in the UI flow: they fetch data through `Services`, react to events from `Controllers`, expose observable state to `Views`, and drive navigation or presentation decisions without embedding UI rendering details.

## Role in the architecture

- Prepare data for screens and reusable view flows.
- Translate user interactions into service calls, playback actions, or navigation.
- Expose observable state that SwiftUI views can bind to.
- Keep the `Views` layer focused on presentation rather than business logic.

Across this directory, the common pattern is:

- A protocol defines the expected behavior of a view model.
- A concrete `...Impl` type implements that behavior.
- Dependencies are injected from the IoC container rather than created internally.

## Directory structure

### `SongList`

The home/search screen view model lives in `ViewModels/SongList`.

- `SongListViewModel.swift`: the public contract for the song list screen.
- `SongListViewModelImpl.swift`: coordinates recently played songs, search state, song selection, and album navigation.

This view model is responsible for switching between:

- a recent songs list backed by `InteractionService`
- a search results list backed by `SongSearchService`

It also drives the song player and album navigation flows when the user selects a song or album.

### `SongPlayer`

The player screen view model lives in `ViewModels/SongPlayer`.

- `FocusedSongPlayerViewModel.swift`: defines the focused player contract used by the playback UI controls.
- `FocusedSimpleSongPlayerViewModelImpl.swift`: coordinates the playback queue, playback controller, repeat behavior, progress updates, and recent-play persistence.
- `CompleteSongPlayerViewModel.swift`: defines the higher-level player flow that combines the focused player, the visible song list, and album presentation.
- `CompleteSongPlayerViewModelImpl.swift`: wires a paginated song list into a playback queue and composes the focused player with album navigation.

Together, these types split playback into:

- a focused player responsible for playback mechanics
- a complete player responsible for the full-screen player flow and related navigation

### `Album`

The album details screen view model lives in `ViewModels/Album`.

- `AlbumViewModel.swift`: the public contract for album loading and song selection.
- `AlbumViewModelImpl.swift`: loads album details, exposes loading/error state, and opens the complete player for selected album tracks.

### `PaginatedList`

Reusable paginated-list logic lives in `ViewModels/PaginatedList`.

- `PaginatedListViewModel.swift`: defines the base paginated-list APIs and the full paginated contract.
- `PaginatedListViewModelImpl.swift`: implements first-page loading, next-page loading, refresh, error recovery, and tracks the latest load result.
- `PaginatedListPlaybackQueue.swift`: adapts a paginated list into a playback queue, including loading the next page when playback advances beyond the currently loaded items.

This folder provides a key shared abstraction used by multiple features, especially the song list flows.

### `Presentation`

Presentation helpers live in `ViewModels/Presentation`.

- `PresentationViewModel.swift`: a small abstraction for presenting and dismissing another value or view model.
- `PresentationViewModelImpl.swift`: the observable implementation used by screens for navigation and sheet/full-screen presentation state.
- `ErrorPresentation.swift`: maps internal errors into `UserFacingError` values suitable for display.

These helpers support shared presentation patterns and keep user-facing error handling consistent across the app.

## Important components

### `SongListViewModel`

The main view model for the app's home flow.

- Manages both recent songs and search results.
- Exposes optional destination view models that the view binds to for navigation.
- Publishes the latest selected song through observable state for playback coordination.
- Refreshes recent songs when playback interactions change.

### `FocusedSongPlayerViewModel`

The main view model for playback mechanics.

- Observes both the playback queue and the playback controller.
- Tracks playback state, progress, elapsed time, duration, and repeat mode.
- Handles next/previous movement and playback-end behavior.

### `CompleteSongPlayerViewModel`

The higher-level player flow view model.

- Owns the focused player used by the main player controls.
- Exposes the current paginated song list so the full-screen player can render the queue.

### `PaginatedListViewModel`

The reusable pagination engine for list-based features.

- Centralizes paging, refresh, loading-state, and retry behavior.
- Exposes `lastLoadResult`, which other components can observe for the latest page-load outcome.
- Enables features like infinite scrolling and the paginated playback queue.

### `PresentationViewModel`

A lightweight abstraction for navigation/presentation state.

- Lets a view model present another view model without taking a dependency on concrete view code.
- Keeps modal/navigation state observable and easy to reset.

## Important patterns

- View models expose observable state and imperative actions, but not view code.
- Screen-specific view models compose shared helpers such as paginated lists and presentation state instead of reimplementing them.
- The protocol/implementation split keeps the layer testable and friendly to dependency injection.
- Errors are converted into `UserFacingError` values here, close to the UI boundary, so services and controllers can stay focused on lower-level concerns.
