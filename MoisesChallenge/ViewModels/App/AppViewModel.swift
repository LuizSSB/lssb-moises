//
//  AppViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

protocol AppViewModel: ViewModel {
    var songList: any SongListViewModel { get }
    var album: (any AlbumViewModel)? { get set }
    var completePlayer: (any CompleteSongPlayerViewModel)? { get set }
    var miniPlayer: (any FocusedSongPlayerViewModel)? { get }

    func setup()
    func setCompletePlayer(presented: Bool)
}
