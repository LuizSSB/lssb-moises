//
//  AppViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

protocol AppViewModel: ViewModel {
    var songList: any SongListViewModel { get }
    var album: (any AlbumViewModel)? { get set }
    var player: (any CompleteSongPlayerViewModel)? { get set }
    var innerPlayer: (any CompleteSongPlayerViewModel)? { get }
    
    func setup()
    func setPlayer(presented: Bool)
}
