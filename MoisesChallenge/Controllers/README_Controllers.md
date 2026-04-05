# Controllers

This directory contains controller-layer types: focused pieces of business logic that do not fit the responsibilities of `Services` or screen-specific `ViewModels`.

Controllers are meant to be small, reusable, and ignorant of UI details. In this project they are used to coordinate playback behavior and lightweight event delivery across layers.

## Role in the architecture

- Encapsulate supporting business logic that can be shared by `Services` and `ViewModels`.
- Expose narrow interfaces so concrete implementations can be swapped through the app's IoC container.
- Emit async updates without tightly coupling callers to a specific implementation.

## Important components

### `Event.swift`

A small generic event primitive built on top of `AsyncStream`.

- Implemented as an `actor`, so observer management stays concurrency-safe.
- Lets clients subscribe through `stream()` and receive values asynchronously.
- Used across the app anywhere a controller or view model needs to broadcast state changes.

### `Playback/SongPlaybackController.swift`

Defines the playback controller contract used by the song player flow.

- Declares the playback lifecycle API: `load`, `play`, `pause`, `seek`, `restart`, and `stop`.
- Exposes `SongPlaybackControllerEvent`, which describes the key playback events:
  - ready to play
  - progress updates
  - playback finished
  - playback failure

### `Playback/AVSongPlaybackController.swift`

Concrete `SongPlaybackController` implementation backed by `AVPlayer`.

- Loads the song preview URL into an `AVPlayerItem`.
- Starts playback and observes readiness, progress, and playback completion.
- Emits controller events through `Event<SongPlaybackControllerEvent>`.
- Handles transport controls such as pause, seek, restart, and stop.

### `Playback/Queue/PlaybackQueue.swift`

Generic protocol that models navigation through a playable sequence of items.

- Tracks the current item and current index.
- Exposes `currentItemChangedEvent` so listeners can react to queue changes.
- Defines directional navigation through `previous` and `next` moves.

### `Playback/Queue/StaticPlaybackQueue.swift`

Simple in-memory `PlaybackQueue` implementation for a fixed list of items.

- Keeps the selected item in sync with its index inside a static array.
- Supports moving backward and forward when neighboring items exist.
- Emits item-change events whenever the current item changes.

## Notes

- The protocol/implementation split used here keeps higher layers dependent on behavior instead of concrete types.
- The paginated playback queue used by paginated list screens lives in `ViewModels/PaginatedList/PaginatedListPlaybackQueue.swift`, because it depends directly on paginated list view-model state rather than being a fully standalone controller.
