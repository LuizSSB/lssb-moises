//
//  AlbumViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

@MainActor
@Observable
final class AlbumSongListViewModel {
    private(set) var album: ActionStatus<Album, String> = .none
    private(set) var player: SongPlayerViewModel?
    
    private let albumId: String
    private let service: AlbumSearchService
    
    init(albumId: String, service: AlbumSearchService) {
        self.albumId = albumId
        self.service = service
    }
    
    func onAppear() {
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
    }
    
    func onDismissPlayer() {
        player = nil
    }
}
