//
//  AppViewModelImplTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 06/04/26.
//

import Foundation
import Observation
import Testing
@testable import MoisesChallenge

@MainActor
struct AppViewModelImplTests {
    @Test func setup_createsCompletePlayerWhenSongListSelectsSong() async throws {
        // ARRANGE
        let recentList = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let songList = SongListViewModelStub(recentList: recentList)
        let container = IoCContainerSpy(songListStub: songList)
        let viewModel = AppViewModelImpl(container: container)
        viewModel.setup()

        // ACT
        songList.observableSelectedSong = .init(value: TestData.song2)
        await busyWait { viewModel.completePlayer != nil }

        // ASSERT
        let completePlayer = try #require(viewModel.completePlayer as? CompleteSongPlayerViewModelStub)
        let requestedSongList = try #require(container.lastCompletePlayerSongList as? PaginatedListViewModelStub<Song>)
        let actualPlayer = try #require(completePlayer.actualPlayer as? FocusedSongPlayerViewModelStub)
        let miniPlayer = try #require(viewModel.miniPlayer as? FocusedSongPlayerViewModelStub)
        #expect(container.lastSelectedSong == TestData.song2)
        #expect(requestedSongList === recentList)
        #expect(completePlayer === container.lastCompletePlayer)
        #expect(actualPlayer === miniPlayer)
    }

    @Test func setup_showsAlbumAndHidesPresentedPlayerWhenSongListSelectsAlbum() async throws {
        // ARRANGE
        let recentList = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let songList = SongListViewModelStub(recentList: recentList)
        let container = IoCContainerSpy(songListStub: songList)
        let viewModel = AppViewModelImpl(container: container)
        viewModel.setup()
        songList.observableSelectedSong = .init(value: TestData.song1)
        await busyWait { viewModel.completePlayer != nil }
        let miniPlayerBeforeAlbumSelection = try #require(viewModel.miniPlayer as? FocusedSongPlayerViewModelStub)

        // ACT
        songList.observableSelectedAlbumId = .init(value: TestData.album.id)
        await busyWait { viewModel.album != nil && viewModel.completePlayer == nil }

        // ASSERT
        let albumViewModel = try #require(viewModel.album as? AlbumViewModelStub)
        let miniPlayerAfterAlbumSelection = try #require(viewModel.miniPlayer as? FocusedSongPlayerViewModelStub)
        #expect(container.lastAlbumId == TestData.album.id)
        #expect(viewModel.completePlayer == nil)
        #expect(albumViewModel === container.albumViewModelStub)
        #expect(miniPlayerAfterAlbumSelection === miniPlayerBeforeAlbumSelection)
    }

    @Test func setup_createsStaticPlayerQueueWhenAlbumSelectsSong() async {
        // ARRANGE
        let songList = SongListViewModelStub(recentList: PaginatedListViewModelStub(items: []))
        let container = IoCContainerSpy(songListStub: songList)
        let albumViewModel = AlbumViewModelStub(album: .success(TestData.album))
        container.albumViewModelStub = albumViewModel
        let viewModel = AppViewModelImpl(container: container)
        viewModel.album = albumViewModel
        viewModel.setup()

        // ACT
        albumViewModel.observableSelectedSong = .init(value: TestData.song2)
        await busyWait { viewModel.completePlayer != nil }

        // ASSERT
        #expect(container.lastSelectedSong == TestData.song2)
        #expect(container.lastStaticSongListItems == TestData.album.songs)
    }

    @Test func setCompletePlayer_togglesPresentedPlayerWithoutDroppingMiniPlayer() async throws {
        // ARRANGE
        let recentList = PaginatedListViewModelStub(items: [TestData.song1])
        let songList = SongListViewModelStub(recentList: recentList)
        let container = IoCContainerSpy(songListStub: songList)
        let viewModel = AppViewModelImpl(container: container)
        viewModel.setup()
        songList.observableSelectedSong = .init(value: TestData.song1)
        await busyWait { viewModel.completePlayer != nil }
        let originalCompletePlayer = try #require(viewModel.completePlayer as? CompleteSongPlayerViewModelStub)
        let originalMiniPlayer = try #require(viewModel.miniPlayer as? FocusedSongPlayerViewModelStub)

        // ACT
        viewModel.setCompletePlayer(presented: false)

        // ASSERT
        let hiddenMiniPlayer = try #require(viewModel.miniPlayer as? FocusedSongPlayerViewModelStub)
        #expect(viewModel.completePlayer == nil)
        #expect(hiddenMiniPlayer === originalMiniPlayer)

        // ACT
        viewModel.setCompletePlayer(presented: true)

        // ASSERT
        let restoredCompletePlayer = try #require(viewModel.completePlayer as? CompleteSongPlayerViewModelStub)
        let restoredMiniPlayer = try #require(viewModel.miniPlayer as? FocusedSongPlayerViewModelStub)
        #expect(restoredCompletePlayer === originalCompletePlayer)
        #expect(restoredMiniPlayer === originalMiniPlayer)
    }

    @Test func setCompletePlayer_doesNotRedisplayAlbumWhenReopeningPlayerAfterAlbumWasSelectedFromIt() async throws {
        // ARRANGE
        let recentList = PaginatedListViewModelStub(items: [TestData.song1])
        let songList = SongListViewModelStub(recentList: recentList)
        let container = IoCContainerSpy(songListStub: songList)
        let viewModel = AppViewModelImpl(container: container)
        viewModel.setup()
        songList.observableSelectedSong = .init(value: TestData.song1)
        await busyWait { viewModel.completePlayer != nil }
        let completePlayer = try #require(viewModel.completePlayer as? CompleteSongPlayerViewModelStub)

        var songWithAlbum = TestData.song1
        songWithAlbum.album = TestData.album

        // ACT
        completePlayer.selectAlbum(of: songWithAlbum)
        await busyWait { viewModel.album != nil && viewModel.completePlayer == nil }
        let albumShownFromPlayer = try #require(viewModel.album as? AlbumViewModelStub)

        // ACT
        viewModel.setCompletePlayer(presented: true)
        try? await Task.sleep(for: .milliseconds(50))

        // ASSERT
        let reopenedPlayer = try #require(viewModel.completePlayer as? CompleteSongPlayerViewModelStub)
        let albumAfterReopen = try #require(viewModel.album as? AlbumViewModelStub)
        #expect(reopenedPlayer === completePlayer)
        #expect(albumAfterReopen === albumShownFromPlayer)
        #expect(container.albumRequestCount == 1)
    }
}

@MainActor
private final class IoCContainerSpy: IoCContainer {
    let songListStub: SongListViewModelStub

    var albumViewModelStub = AlbumViewModelStub(album: .success(TestData.album))

    private(set) var lastCompletePlayerSongList: (any PaginatedListViewModel<Song>)?
    private(set) var lastSelectedSong: Song?
    private(set) var lastAlbumId: String?
    private(set) var lastStaticSongListItems: [Song]?
    private(set) var lastCompletePlayer: CompleteSongPlayerViewModelStub?
    private(set) var albumRequestCount = 0

    init(songListStub: SongListViewModelStub) {
        self.songListStub = songListStub
    }

    func songListViewModel() -> any SongListViewModel {
        songListStub
    }

    func completeSongPlayerViewModel(
        songList: any PaginatedListViewModel<Song>,
        selectedSong: Song
    ) -> any CompleteSongPlayerViewModel {
        lastCompletePlayerSongList = songList
        lastSelectedSong = selectedSong

        let player = CompleteSongPlayerViewModelStub(songList: songList)
        lastCompletePlayer = player
        return player
    }

    func albumViewModel(albumId: String) -> any AlbumViewModel {
        lastAlbumId = albumId
        albumRequestCount += 1
        return albumViewModelStub
    }

    func paginatedListViewModel<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        ofKind kind: PaginatedListViewModelDependencyKind<Item, PaginationParams>
    ) -> any PaginatedListViewModel<Item> {
        switch kind {
        case let .static(items):
            if let songs = items as? [Song] {
                lastStaticSongListItems = songs
            }
            return PaginatedListViewModelStub(items: items)
        case let .dynamic(fetch):
            return PaginatedListViewModelImpl(fetch: fetch)
        }
    }
}

@MainActor
@Observable
private final class SongListViewModelStub: SongListViewModel {
    let recentList: any PaginatedListViewModel<Song>
    var workingSearchQuery = ""
    var currentQuery = ""
    var searchList: (any PaginatedListViewModel<Song>)?
    var observableSelectedAlbumId: ObservedData<String>?
    var observableSelectedSong: ObservedData<Song>?

    var currentList: any PaginatedListViewModel<Song> {
        searchList ?? recentList
    }

    init(
        recentList: any PaginatedListViewModel<Song>,
        searchList: (any PaginatedListViewModel<Song>)? = nil
    ) {
        self.recentList = recentList
        self.searchList = searchList
    }

    func onAppear() {
    }

    func handleSearchBar(focused: Bool) {
    }

    func submitSearch() {
    }

    func select(song: Song) {
        observableSelectedSong = .init(value: song)
    }

    func selectAlbum(of song: Song) {
        guard let albumId = song.album?.id else { return }
        observableSelectedAlbumId = .init(value: albumId)
    }
}

@MainActor
@Observable
private final class AlbumViewModelStub: AlbumViewModel {
    var album: ActionStatus<Album, UserFacingError>
    var observableSelectedSong: ObservedData<Song>?

    init(album: ActionStatus<Album, UserFacingError>) {
        self.album = album
    }

    func onAppear() {
    }

    func onDisappear() {
    }

    func loadAlbum() {
    }

    func select(song: Song) {
        observableSelectedSong = .init(value: song)
    }
}

@MainActor
@Observable
private final class CompleteSongPlayerViewModelStub: CompleteSongPlayerViewModel {
    let actualPlayer: any FocusedSongPlayerViewModel
    let songList: any PaginatedListViewModel<Song>
    var observableSelectedAlbumId: ObservedData<String>?

    init(
        songList: any PaginatedListViewModel<Song>,
        actualPlayer: any FocusedSongPlayerViewModel = FocusedSongPlayerViewModelStub()
    ) {
        self.songList = songList
        self.actualPlayer = actualPlayer
    }

    func select(song: Song) {
    }

    func selectAlbum(of song: Song) {
        guard let albumId = song.album?.id else { return }
        observableSelectedAlbumId = .init(value: albumId)
    }
}

@MainActor
@Observable
private final class FocusedSongPlayerViewModelStub: FocusedSongPlayerViewModel {
    var playbackState: PlaybackState = .idle
    var currentSong: Song?
    var repeatMode: PlaybackRepeatMode = .none
    var progress: Double = 0
    var elapsed: TimeInterval = 0
    var duration: TimeInterval?

    func onAppear() {
    }

    func isLoading(_ direction: PlaybackQueueDirection) -> Bool {
        false
    }

    func has(_ direction: PlaybackQueueDirection) -> Bool {
        false
    }

    func togglePlayPause() {
    }

    func pause() {
    }

    func toggleRepeatMode() {
    }

    func seek(to fraction: Double) {
    }

    func move(to direction: PlaybackQueueDirection) {
    }
}

@MainActor
@Observable
private final class PaginatedListViewModelStub<Item: Hashable & Sendable>: PaginatedListViewModel {
    var items: [Item]
    var loadState: PaginatedListLoadState = .loaded
    var hasMore = false
    var lastLoadResult: Result<[Item], Error>?

    init(items: [Item]) {
        self.items = items
    }

    func loadFirstPageIfNeeded() {
    }

    func loadNextPage() {
    }

    func refresh() async {
    }

    func interactWithError(shouldRetry: Bool) {
    }

    func reset() {
    }
}
