//
//  AlbumViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

@Observable
class AlbumViewModelImpl: AlbumViewModel {
    var album: ActionStatus<Album, String> = .none
    private(set) var player: any PresentationViewModel<any SongPlayerViewModel>
    
    private let albumId: String
    private let service: AlbumSearchService
    private let container: any IoCContainer
    
    init(albumId: String, service: AlbumSearchService, container: any IoCContainer) {
        self.albumId = albumId
        self.service = service
        self.container = container
        self.player = container.presentationViewModel()
    }
    
    func onAppear() {
        guard case .none = album else { return }
        loadAlbum()
    }
    
    func loadAlbum() {
        guard !album.isRunning else { return }
        
        album = .running
        
        Task {
            do {
                let album = try await service.get(albumId)
                withAnimation {
                    self.album = .success(album)
                }
            } catch {
                withAnimation {
                    album = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    func onSelect(song: Song) {
        guard case let .success(album) = album,
              let songs = album.songs,
              let queue = PlaybackQueue(songs: songs, selectedSong: song)
        else { return }
        
        let viewModel = container.songPlayerViewModel(queue: queue)
        player.present(viewModel)
    }
}
