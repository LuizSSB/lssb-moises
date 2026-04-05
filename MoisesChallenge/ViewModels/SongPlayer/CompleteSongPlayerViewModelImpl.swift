//
//  CompleteSongPlayerViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

final class CompleteSongPlayerViewModelImpl: CompleteSongPlayerViewModel {
    let actualPlayer: any FocusedSongPlayerViewModel
    let songList: any PaginatedListViewModel<Song>
    private(set) var album: any PresentationViewModel<any AlbumViewModel>
    
    private let container: any IoCContainer
    
    init(
        songList: any PaginatedListViewModel<Song>,
        selectedSong: Song,
        container: any IoCContainer
    ) {
        let queue = container.playbackQueue(ofKind: .paginated(songList), selectedItem: selectedSong)
        self.actualPlayer = container.focusedSongPlayerViewModel(queue: queue)
        self.songList = songList
        self.album = container.presentationViewModel()
        self.container = container
    }
    
    func select(song: Song) {
//        actualPlayer.currentSong = song
    }
    
    func selectAlbum(of song: Song) {
        guard let songAlbum = song.album else { return }
        album.present(container.albumViewModel(albumId: songAlbum.id))
    }
}
