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
    var player: (any CompleteSongPlayerViewModel)?
    
    private(set) var innerPlayer: (any CompleteSongPlayerViewModel)?

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
    
    func setPlayer(presented: Bool) {
        if presented {
            guard let innerPlayer else { return }
            player = innerPlayer
        } else {
            player = nil
        }
    }
    
    private func handlePlaybackRequired(songList: any PaginatedListViewModel<Song>, selectedSong: Song) {
        innerPlayer = container.completeSongPlayerViewModel(
            songList: songList,
            selectedSong: selectedSong
        )
        player = innerPlayer
    }
}
