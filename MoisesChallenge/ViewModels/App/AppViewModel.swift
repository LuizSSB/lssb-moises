//
//  AppViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

@MainActor
protocol AppViewModel: AnyObject {
    var songList: any SongListViewModel { get }
    var album: any PresentationViewModel<AlbumViewModel> { get }
    var player: any PresentationViewModel<CompleteSongPlayerViewModel> { get }
    var innerPlayer: (any CompleteSongPlayerViewModel)? { get }
    
    func setup()
    func setPlayer(presented: Bool)
}
