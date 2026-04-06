//
//  AppViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

import Observation

@Observable
final class AppViewModelImpl: AppViewModel {
    let songList: any SongListViewModel
    var album: (any AlbumViewModel)?
    var completePlayer: (any CompleteSongPlayerViewModel)?
    var miniPlayer: (any FocusedSongPlayerViewModel)? {
        actualCompletePlayer?.actualPlayer
    }
    
    private var actualCompletePlayer: (any CompleteSongPlayerViewModel)? {
        didSet {
            completePlayer = actualCompletePlayer
        }
    }

    private let container: any IoCContainer

    @ObservationIgnored private var hasSetObserversUp = false

    init(container: any IoCContainer) {
        self.songList = container.songListViewModel()
        self.container = container
    }
    
    func setup() {
        guard !hasSetObserversUp else { return }
        hasSetObserversUp = true

        observeListSongSelection()
        observeListAlbumSelection()
        observeAlbumSongSelection()
        observePlayerAlbumSelection()
    }
    
    private func observeListSongSelection() {
        withObservationTracking {
            _ = songList.observableSelectedSong
        } onChangeAsync: { [weak self] in
            guard let self else { return }
            await self.observeListSongSelection()
            guard let song =  await self.songList.observableSelectedSong?.value else { return }
            await self.handlePlaybackRequired(songList: self.songList.currentList, selectedSong: song)
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
    
    private func observePlayerAlbumSelection() {
        withObservationTracking {
            _ = completePlayer?.observableSelectedAlbumId
        } onChangeAsync: { [weak self] in
            guard let self else { return }
            await self.observePlayerAlbumSelection()
            guard let albumId = await self.completePlayer?.observableSelectedAlbumId?.value else { return }
            await self.handleAlbumDisplayRequired(albumId: albumId)
        }
    }
    
    private func handleAlbumDisplayRequired(albumId: String) {
        completePlayer = nil
        
        guard album?.album.result?.id != albumId else { return }
        album = container.albumViewModel(albumId: albumId)
    }

    func setCompletePlayer(presented: Bool) {
        if presented {
            guard let actualCompletePlayer else { return }
            completePlayer = actualCompletePlayer
        } else {
            completePlayer = nil
        }
    }
    
    private func handlePlaybackRequired(songList: any PaginatedListViewModel<Song>, selectedSong: Song) {
        actualCompletePlayer = container.completeSongPlayerViewModel(
            songList: songList,
            selectedSong: selectedSong
        )
    }
}
