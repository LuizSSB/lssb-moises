//
//  AppViewModel.swift
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
        self.songList = container.songListViewModel()
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
            await self.observeListSongSelection()
            guard let song =  await self.songList.observableSelectedSong?.value else { return }
            let list = if await self.songList.currentQuery.isEmpty {
                await self.container.recentSongsPaginatedListViewModel()
            } else {
                await self.container.songSearchPaginatedListViewModel(
                    params: .init(searchTerm: self.songList.currentQuery),
                    initialEntries: self.songList.searchList?.items ?? []
                )
            }
            await self.handlePlaybackRequired(songList: list, selectedSong: song)
        }
    }
    
    private func observeAlbumSongSelection() {
        withObservationTracking {
            _ = album?.observableSelectedSong
        } onChangeAsync: { @MainActor [weak self] in
            guard let self else { return }
            self.observeAlbumSongSelection()
            
            guard let song = album?.observableSelectedSong?.value else { return }
            self.handlePlaybackRequired(
                songList: self.container.paginatedListViewModel(
                    ofKind: .init(staticItems: self.album?.album.result?.songs ?? [song])
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
            await self.observeListAlbumSelection()
            
            guard let albumId = await self.songList.observableSelectedAlbumId?.value else { return }
            await self.handleAlbumDisplayRequired(albumId: albumId)
        }
    }
    
    private func observePlayerAlbumSelection(lastEventData: ObservedData<String>? = nil) {
        withObservationTracking {
            _ = completePlayer?.observableSelectedAlbumId
        } onChangeAsync: { [weak self] in
            guard let self else { return }
            guard let selection = await self.completePlayer?.observableSelectedAlbumId,
                  lastEventData?.id != selection.id
            else {
                await self.observePlayerAlbumSelection(lastEventData: lastEventData)
                return
            }
            await self.observePlayerAlbumSelection(lastEventData: selection)
            await self.handleAlbumDisplayRequired(albumId: selection.value)
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
