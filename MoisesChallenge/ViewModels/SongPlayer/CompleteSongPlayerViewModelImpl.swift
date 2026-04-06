//
//  CompleteSongPlayerViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

final class CompleteSongPlayerViewModelImpl: CompleteSongPlayerViewModel {
    let actualPlayer: any FocusedSongPlayerViewModel
    let songList: any PaginatedListViewModel<Song>
    
    private let queue: any PlaybackQueue<Song>
    
    init(
        songList: any PaginatedListViewModel<Song>,
        selectedSong: Song,
        container: any IoCContainer
    ) {
        let queue = container.playbackQueue(ofKind: .paginated(songList), selectedItem: selectedSong)
        self.queue = queue
        self.actualPlayer = container.focusedSongPlayerViewModel(queue: queue)
        self.songList = songList
    }
    
    func select(song: Song) {
        guard let index = songList.items.firstIndex(of: song) else { return }
        queue.currentIndex = index
    }
    
    func selectAlbum(of song: Song) {
        guard let songAlbum = song.album else { return }
//        album.present(container.albumViewModel(albumId: songAlbum.id))
    }
}
