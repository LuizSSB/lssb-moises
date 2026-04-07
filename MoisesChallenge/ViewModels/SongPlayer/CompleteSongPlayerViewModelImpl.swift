//
//  CompleteSongPlayerViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

import Observation

@Observable
final class CompleteSongPlayerViewModelImpl: CompleteSongPlayerViewModel {
    // MARK: - Public State

    let actualPlayer: any FocusedSongPlayerViewModel
    let songList: any PaginatedListViewModel<Song>

    var observableSelectedAlbumId: ObservedData<String>?

    // MARK: - Dependencies

    private let queue: any PlaybackQueue<Song>

    // MARK: - Lifecycle

    init(
        songList: any PaginatedListViewModel<Song>,
        selectedSong: Song,
        container: any IoCContainer
    ) {
        queue = container.playbackQueue(ofKind: .paginated(songList), selectedItem: selectedSong)
        actualPlayer = container.focusedSongPlayerViewModel(queue: queue)
        self.songList = songList
    }

    // MARK: - Screen Events

    func select(song: Song) {
        guard let index = songList.items.firstIndex(of: song) else { return }
        queue.currentIndex = index
    }

    func selectAlbum(of song: Song) {
        guard let songAlbum = song.album else { return }
        observableSelectedAlbumId = .init(value: songAlbum.id)
    }
}
