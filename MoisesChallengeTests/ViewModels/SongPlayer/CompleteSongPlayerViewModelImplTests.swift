//
//  CompleteSongPlayerViewModelImplTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 05/04/26.
//

import Foundation
import Observation
import Testing
@testable import MoisesChallenge

@MainActor
struct CompleteSongPlayerViewModelImplTests {
    @Test func init_keepsSongListAndBuildsFocusedPlayerFromPaginatedQueue() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let container = IoCContainerSpy()
        let appCoordinator = AppCoordinatorSpy()

        // ACT
        let viewModel = CompleteSongPlayerViewModelImpl(
            songList: list,
            selectedSong: TestData.song1,
            container: container,
            appCoordinator: appCoordinator
        )

        // ASSERT
        #expect(viewModel.songList === list)
        #expect(viewModel.actualPlayer as? FocusedSongPlayerViewModelStub === container.focusedPlayerStub)
        #expect(container.capturedSongList === list)
        #expect(container.capturedSelectedSong == TestData.song1)
    }

    @Test func select_movesQueueToMatchingSongIndex() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1, TestData.song2])
        let container = IoCContainerSpy()
        let appCoordinator = AppCoordinatorSpy()
        let viewModel = CompleteSongPlayerViewModelImpl(
            songList: list,
            selectedSong: TestData.song1,
            container: container,
            appCoordinator: appCoordinator
        )

        // ACT
        viewModel.select(song: TestData.song2)

        // ASSERT
        #expect(container.playbackQueueSpy.currentIndex == 1)
        #expect(container.playbackQueueSpy.currentItem == TestData.song2)
    }

    @Test func selectAlbum_presentsAlbumViewModelWhenSongHasAlbum() throws {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1])
        let container = IoCContainerSpy()
        let appCoordinator = AppCoordinatorSpy()
        let viewModel = CompleteSongPlayerViewModelImpl(
            songList: list,
            selectedSong: TestData.song1,
            container: container,
            appCoordinator: appCoordinator
        )
        var song = TestData.song1
        song.album = TestData.album

        // ACT
        viewModel.selectAlbum(of: song)

        // ASSERT
        #expect(appCoordinator.capturedAlbumId == TestData.album.id)
    }

    @Test func selectAlbum_doesNothingWhenSongHasNoAlbum() {
        // ARRANGE
        let list = PaginatedListViewModelStub(items: [TestData.song1])
        let container = IoCContainerSpy()
        let appCoordinator = AppCoordinatorSpy()
        let viewModel = CompleteSongPlayerViewModelImpl(
            songList: list,
            selectedSong: TestData.song1,
            container: container,
            appCoordinator: appCoordinator
        )

        // ACT
        viewModel.selectAlbum(of: TestData.song1)

        // ASSERT
        #expect(appCoordinator.capturedAlbumId == nil)
    }
}

@MainActor
private final class IoCContainerSpy: IoCContainer {
    let focusedPlayerStub = FocusedSongPlayerViewModelStub()
    let playbackQueueSpy = PlaybackQueueSpy(items: [TestData.song1, TestData.song2], selectedItem: TestData.song1)

    private(set) var capturedSongList: (any PaginatedListViewModel<Song>)?
    private(set) var capturedSelectedSong: Song?

    func focusedSongPlayerViewModel(queue: any PlaybackQueue<Song>) -> any FocusedSongPlayerViewModel {
        focusedPlayerStub
    }

    func presentationViewModel<T>() -> any PresentationViewModel<T> {
        PresentationViewModelImpl<T>()
    }

    func playbackQueue<Item: Equatable & Hashable & Sendable>(
        ofKind kind: PlaybackQueueDependencyKind<Item>,
        selectedItem: Item
    ) -> any PlaybackQueue<Item> {
        capturedSelectedSong = selectedItem as? Song

        switch kind {
        case let .paginated(list):
            capturedSongList = list as? any PaginatedListViewModel<Song>
            playbackQueueSpy.replaceItems((list as? any PaginatedListViewModel<Song>)?.items ?? [])
        case let .static(items):
            playbackQueueSpy.replaceItems(items as? [Song] ?? [])
        }

        playbackQueueSpy.currentItem = selectedItem as? Song
        playbackQueueSpy.currentIndex = playbackQueueSpy.items.firstIndex(of: selectedItem as? Song ?? TestData.song1)

        return playbackQueueSpy as! any PlaybackQueue<Item>
    }
}

@MainActor
private final class AppCoordinatorSpy: AppCoordinator {
    private(set) var capturedAlbumId: String?

    func play(song: Song, from songList: any PaginatedListViewModel<Song>) {
    }

    func showAlbum(albumId: String) {
        capturedAlbumId = albumId
    }

    func presentPlayer() {
    }

    func dismissPlayer() {
    }
}

@MainActor
@Observable
private final class PaginatedListViewModelStub: PaginatedListViewModel {
    var items: [Song]
    var loadState: PaginatedListLoadState = .loaded
    var hasMore = false
    var lastLoadResult: Result<[Song], Error>?

    init(items: [Song]) {
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

@MainActor
@Observable
private final class PlaybackQueueSpy: PlaybackQueue {
    fileprivate var items: [Song]
    var currentItem: Song?
    var currentIndex: Int? {
        didSet {
            guard let currentIndex, items.indices.contains(currentIndex) else {
                currentItem = nil
                return
            }
            currentItem = items[currentIndex]
        }
    }

    init(items: [Song], selectedItem: Song) {
        self.items = items
        self.currentIndex = items.firstIndex(of: selectedItem)
        self.currentItem = selectedItem
    }

    func replaceItems(_ items: [Song]) {
        self.items = items
    }

    func isLoading(_ direction: PlaybackQueueDirection) -> Bool {
        false
    }

    func has(_ direction: PlaybackQueueDirection) -> Bool {
        false
    }

    func move(to direction: PlaybackQueueDirection) async throws {
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

    func onDisappear() {
    }

    func isLoading(_ direction: PlaybackQueueDirection) -> Bool {
        false
    }

    func has(_ direction: PlaybackQueueDirection) -> Bool {
        false
    }

    func togglePlayPause() {
    }

    func toggleRepeatMode() {
    }

    func seek(to fraction: Double) {
    }

    func move(to direction: PlaybackQueueDirection) {
    }
}
