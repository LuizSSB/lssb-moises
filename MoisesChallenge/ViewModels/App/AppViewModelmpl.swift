//
//  AppViewModelmpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

import Foundation
import Observation

@Observable
final class AppViewModelImpl: AppViewModel {
    // MARK: - Public State

    let songList: any SongListViewModel
    var album: (any AlbumViewModel)?
    var completePlayer: (any CompleteSongPlayerViewModel)?
    var miniPlayer: (any FocusedSongPlayerViewModel)? {
        actualCompletePlayer?.actualPlayer
    }

    // MARK: - Private State

    @ObservationIgnored private var actualCompletePlayer: (any CompleteSongPlayerViewModel)? {
        didSet {
            completePlayer = actualCompletePlayer
        }
    }

    @ObservationIgnored private var hasSetObserversUp = false

    // MARK: - Dependencies

    private let container: any IoCContainer

    // MARK: - Lifecycle

    init(container: any IoCContainer) {
        songList = container.songListViewModel()
        self.container = container
    }

    // MARK: - App Events

    func setup() {
        guard !hasSetObserversUp else { return }
        hasSetObserversUp = true

        observeListSongSelection()
        observeListAlbumSelection()
        observeAlbumSongSelection()
        observePlayerAlbumSelection()
    }

    func setCompletePlayer(presented: Bool) {
        if presented {
            guard let actualCompletePlayer else { return }
            completePlayer = actualCompletePlayer
        } else {
            completePlayer = nil
        }
    }

    // MARK: - Observers

    private func observeListSongSelection() {
        withObservationTracking {
            _ = songList.observableSelectedSong
        } onChangeAsync: { [weak self] in
            guard let self else { return }
            await observeListSongSelection()
            guard let song = await songList.observableSelectedSong?.value else { return }
            let list = if await songList.currentQuery.isEmpty {
                await container.recentSongsPaginatedListViewModel()
            } else {
                await container.songSearchPaginatedListViewModel(
                    params: .init(searchTerm: songList.currentQuery),
                    initialEntries: songList.searchList?.items ?? []
                )
            }
            await handlePlaybackRequired(songList: list, selectedSong: song)
        }
    }

    private func observeAlbumSongSelection() {
        withObservationTracking {
            _ = album?.observableSelectedSong
        } onChangeAsync: { @MainActor [weak self] in
            guard let self else { return }
            observeAlbumSongSelection()

            guard let song = album?.observableSelectedSong?.value else { return }
            handlePlaybackRequired(
                songList: container.paginatedListViewModel(
                    ofKind: .init(staticItems: album?.album.result?.songs ?? [song])
                ),
                selectedSong: song
            )
        }
    }

    private func observeListAlbumSelection() {
        withObservationTracking {
            _ = songList.observableSelectedAlbumId
        } onChangeAsync: { [weak self] in
            guard let self else { return }
            await observeListAlbumSelection()

            guard let albumId = await songList.observableSelectedAlbumId?.value else { return }
            await handleAlbumDisplayRequired(albumId: albumId)
        }
    }

    private func observePlayerAlbumSelection(lastEventData: ObservedData<String>? = nil) {
        withObservationTracking {
            _ = completePlayer?.observableSelectedAlbumId
        } onChangeAsync: { [weak self] in
            guard let self else { return }
            guard let selection = await completePlayer?.observableSelectedAlbumId,
                  lastEventData?.id != selection.id
            else {
                await observePlayerAlbumSelection(lastEventData: lastEventData)
                return
            }
            await observePlayerAlbumSelection(lastEventData: selection)
            await handleAlbumDisplayRequired(albumId: selection.value)
        }
    }

    // MARK: - Observation handlers

    private func handleAlbumDisplayRequired(albumId: String) {
        completePlayer = nil

        guard album?.album.result?.id != albumId else { return }
        album = container.albumViewModel(albumId: albumId)
    }

    private func handlePlaybackRequired(songList: any PaginatedListViewModel<Song>, selectedSong: Song) {
        actualCompletePlayer = container.completeSongPlayerViewModel(
            songList: songList,
            selectedSong: selectedSong
        )
    }
}
