//
//  AppViewModelImplTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 06/04/26.
//

import Foundation
@testable import MoisesChallenge
import Observation
import Testing

@MainActor
struct AppViewModelImplTests {
    @Test func setup_createsCompletePlayerWhenSongListSelectsSong() async throws {
        // ARRANGE
        let recentList = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let songList = SongListViewModelStub(recentList: recentList)
        let container = IoCContainerSpy(songListStub: songList)
        container.nextRecentSongsListItems = recentList.items
        let viewModel = AppViewModelImpl(container: container)
        viewModel.setup()

        // ACT
        songList.observableSelectedSong = ObservedData(value: TestData.song2)
        await busyWait { viewModel.completePlayer != nil }

        // ASSERT
        let completePlayer = try #require(viewModel.completePlayer as? CompleteSongPlayerViewModelStub)
        let requestedSongList = try #require(container.lastCompletePlayerSongList as? PaginatedListViewModelStub<Song>)
        let actualPlayer = try #require(completePlayer.actualPlayer as? FocusedSongPlayerViewModelStub)
        let miniPlayer = try #require(viewModel.miniPlayer as? FocusedSongPlayerViewModelStub)
        #expect(container.lastSelectedSong == TestData.song2)
        #expect(requestedSongList !== recentList)
        #expect(requestedSongList.items == recentList.items)
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

    @Test func setup_refreshingAndLoadingMoreInCompletePlayerAfterRecentSelectionDoesNotAffectSongListLists() async throws {
        // ARRANGE
        let recentList = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let songList = SongListViewModelStub(recentList: recentList)
        let container = IoCContainerSpy(songListStub: songList)
        container.nextRecentSongsListItems = [TestData.song1, TestData.song2]
        let viewModel = AppViewModelImpl(container: container)
        viewModel.setup()

        // ACT
        songList.observableSelectedSong = .init(value: TestData.song2)
        await busyWait { viewModel.completePlayer != nil }

        let completePlayer = try #require(viewModel.completePlayer as? CompleteSongPlayerViewModelStub)
        let completePlayerSongList = try #require(completePlayer.songList as? PaginatedListViewModelStub<Song>)
        completePlayerSongList.refreshedItems = [TestData.song3]
        completePlayerSongList.nextPageItems = [TestData.song1]

        await completePlayer.songList.refresh()
        completePlayer.songList.loadNextPage()

        // ASSERT
        #expect(container.lastSelectedSong == TestData.song2)
        #expect(completePlayerSongList !== recentList)
        #expect(completePlayerSongList.refreshCallCount == 1)
        #expect(completePlayerSongList.loadNextPageCallCount == 1)
        #expect(completePlayerSongList.items == [TestData.song3, TestData.song1])
        #expect(recentList.refreshCallCount == 0)
        #expect(recentList.loadNextPageCallCount == 0)
        #expect(recentList.items == [TestData.song1, TestData.song2])
        #expect(songList.searchList == nil)
    }

    @Test func setup_refreshingAndLoadingMoreInCompletePlayerAfterSearchSelectionDoesNotAffectSongListLists() async throws {
        // ARRANGE
        let recentList = PaginatedListViewModelStub(items: [TestData.song3])
        let searchList = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let songList = SongListViewModelStub(recentList: recentList, searchList: searchList)
        songList.currentQuery = "beatles"
        let container = IoCContainerSpy(songListStub: songList)
        container.nextSearchSongsListItems = [TestData.song1, TestData.song2]
        let viewModel = AppViewModelImpl(container: container)
        viewModel.setup()

        // ACT
        songList.observableSelectedSong = ObservedData(value: TestData.song1)
        await busyWait { viewModel.completePlayer != nil }

        let completePlayer = try #require(viewModel.completePlayer as? CompleteSongPlayerViewModelStub)
        let completePlayerSongList = try #require(completePlayer.songList as? PaginatedListViewModelStub<Song>)
        completePlayerSongList.refreshedItems = [TestData.song3]
        completePlayerSongList.nextPageItems = [TestData.song2]

        await completePlayer.songList.refresh()
        completePlayer.songList.loadNextPage()

        // ASSERT
        #expect(container.lastSelectedSong == TestData.song1)
        #expect(completePlayerSongList !== searchList)
        #expect(completePlayerSongList.refreshCallCount == 1)
        #expect(completePlayerSongList.loadNextPageCallCount == 1)
        #expect(completePlayerSongList.items == [TestData.song3, TestData.song2])
        #expect(searchList.refreshCallCount == 0)
        #expect(searchList.loadNextPageCallCount == 0)
        #expect(searchList.items == [TestData.song1, TestData.song2])
        #expect(recentList.refreshCallCount == 0)
        #expect(recentList.loadNextPageCallCount == 0)
        #expect(recentList.items == [TestData.song3])
    }
}

@MainActor
private final class IoCContainerSpy: IoCContainer {
    let songListStub: SongListViewModelStub

    var albumViewModelStub = AlbumViewModelStub(album: .success(TestData.album))
    var nextRecentSongsListItems: [Song] = []
    var nextSearchSongsListItems: [Song] = []

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
            return PaginatedListViewModelStub<Item>(items: items)
        case let .dynamic(fetch, _):
            if PaginationParams.self == NullPaginationParams.self,
               let items = nextRecentSongsListItems as? [Item]
            {
                return PaginatedListViewModelStub<Item>(items: items)
            }
            if PaginationParams.self == SongSearchParams.self,
               let items = nextSearchSongsListItems as? [Item]
            {
                return PaginatedListViewModelStub<Item>(items: items)
            }
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

    func onAppear() {}

    func handleSearchBar(focused _: Bool) {}

    func submitSearch() {}

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

    func onAppear() {}

    func onDisappear() {}

    func loadAlbum() {}

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

    func select(song _: Song) {}

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

    func onAppear() {}

    func isLoading(_: PlaybackQueueDirection) -> Bool {
        false
    }

    func has(_: PlaybackQueueDirection) -> Bool {
        false
    }

    func togglePlayPause() {}

    func pause() {}

    func toggleRepeatMode() {}

    func seek(to _: Double) {}

    func move(to _: PlaybackQueueDirection) {}
}

@MainActor
@Observable
private final class PaginatedListViewModelStub<Item: Hashable & Sendable>: PaginatedListViewModel {
    var items: [Item]
    var loadState: PaginatedListLoadState = .loaded
    var hasMore = false
    var lastLoadResult: Result<[Item], Error>?
    private(set) var loadFirstPageIfNeededCallCount = 0
    private(set) var loadNextPageCallCount = 0
    private(set) var refreshCallCount = 0
    var refreshedItems: [Item]?
    var nextPageItems: [Item] = []

    init(items: [Item]) {
        self.items = items
    }

    func loadFirstPageIfNeeded() {
        loadFirstPageIfNeededCallCount += 1
    }

    func loadNextPage() {
        loadNextPageCallCount += 1
        items.append(contentsOf: nextPageItems)
    }

    func refresh() async {
        refreshCallCount += 1
        if let refreshedItems {
            items = refreshedItems
        }
    }

    func interactWithError(shouldRetry _: Bool) {}

    func reset() {}
}
