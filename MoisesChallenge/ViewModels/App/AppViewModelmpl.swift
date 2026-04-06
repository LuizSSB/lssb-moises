//
//  AppViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

import Observation

@Observable
final class AppViewModelImpl: AppViewModel {
    var songList: any SongListViewModel
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
    
    private var lifetimeTasks = Set<Task<Void, Never>>() // never really disposed of, since this view model is meant to be active for as long as the app is on

    init(container: any IoCContainer) {
        self.songList = container.songListViewModel()
        self.container = container
    }
    
    func setup() {
        guard lifetimeTasks.isEmpty else { return }
        
        let listPlaybackEvent = songList.songSelectedEvent
        lifetimeTasks.insert(Task { [weak self] in
            for await song in await listPlaybackEvent.stream().stream {
                guard let self else { return }
                self.handlePlaybackRequired(songList: self.songList.currentList, selectedSong: song)
            }
        })
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
