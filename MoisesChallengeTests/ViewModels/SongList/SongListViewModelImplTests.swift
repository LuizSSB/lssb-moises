//
//  SongListViewModelImplTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 05/04/26.
//

import Foundation
import Observation
import Testing
@testable import MoisesChallenge

@MainActor
struct SongListViewModelImplTests {

    @Test func init_startsWithRecentListAsCurrentListAndWithoutSearchList() {
        // ARRANGE
        let container = IoCContainerStub()

        // ACT
        let viewModel = makeViewModel(container: container)

        // ASSERT
        #expect(viewModel.searchList == nil)
        #expect((viewModel.currentList as? PaginatedListViewModelSpy<Song, NullPaginationParams>) === container.recentListSpy)
        #expect(viewModel.currentQuery.isEmpty)
        #expect(viewModel.workingSearchQuery.isEmpty)
    }

    @Test func onAppear_refreshesRecentListWhenSearchListIsNotShowing() async {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)

        // ACT
        viewModel.onAppear()
        await busyWait { container.recentListSpy.refreshCallCount == 1 }

        // ASSERT
        #expect(container.recentListSpy.refreshCallCount == 1)
        #expect(container.recentListSpy.loadFirstPageIfNeededCallCount == 0)
    }

    @Test func onAppear_doesNothingWhenSearchListIsShowing() {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        viewModel.handleSearchBar(focused: true)

        // ACT
        viewModel.onAppear()

        // ASSERT
        #expect(container.recentListSpy.refreshCallCount == 0)
        #expect(container.recentListSpy.loadFirstPageIfNeededCallCount == 0)
    }

    @Test func handleSearchBar_focusedCreatesSearchListAndMakesItCurrent() {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)

        // ACT
        viewModel.handleSearchBar(focused: true)

        // ASSERT
        #expect((viewModel.searchList as? PaginatedListViewModelSpy<Song, SongSearchParams>) === container.searchListSpy)
        #expect((viewModel.currentList as? PaginatedListViewModelSpy<Song, SongSearchParams>) === container.searchListSpy)
    }

    @Test func handleSearchBar_notFocusedClearsSearchStateAndLoadsRecentList() async {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        viewModel.onAppear()
        await busyWait { container.recentListSpy.refreshCallCount == 1 }
        viewModel.handleSearchBar(focused: true)
        viewModel.workingSearchQuery = "submitted"
        viewModel.submitSearch()
        await busyWait { container.searchListSpy.refreshCallCount == 1 }

        // ACT
        viewModel.handleSearchBar(focused: false)

        // ASSERT
        #expect(viewModel.searchList == nil)
        #expect((viewModel.currentList as? PaginatedListViewModelSpy<Song, NullPaginationParams>) === container.recentListSpy)
        #expect(viewModel.workingSearchQuery.isEmpty)
        #expect(viewModel.currentQuery.isEmpty)
        #expect(container.recentListSpy.loadFirstPageIfNeededCallCount == 1)
        #expect(container.recentListSpy.refreshCallCount == 1)
    }

    @Test func submitSearch_trimsQueryUpdatesCurrentQueryAndRefreshesSearchList() async {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        viewModel.handleSearchBar(focused: true)
        viewModel.workingSearchQuery = "  hello world  "

        // ACT
        viewModel.submitSearch()
        await busyWait { container.searchListSpy.refreshCallCount == 1 }

        // ASSERT
        #expect(viewModel.currentQuery == "hello world")
        #expect(container.searchListSpy.refreshCallCount == 1)
    }

    @Test func submitSearch_doesNothingWhenTrimmedQueryIsEmptyOrUnchanged() async {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        viewModel.handleSearchBar(focused: true)
        viewModel.workingSearchQuery = "   "

        // ACT
        viewModel.submitSearch()

        // ASSERT
        #expect(viewModel.currentQuery.isEmpty)
        #expect(container.searchListSpy.refreshCallCount == 0)

        // ACT
        viewModel.workingSearchQuery = "query"
        viewModel.submitSearch()
        await busyWait { container.searchListSpy.refreshCallCount == 1 }
        viewModel.workingSearchQuery = "query"
        viewModel.submitSearch()

        // ASSERT
        #expect(viewModel.currentQuery == "query")
        #expect(container.searchListSpy.refreshCallCount == 1)
    }

    @Test func select_usesRecentListQueueWhenSearchListIsNotShowingAndPresentsPlayer() throws {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)

        // ACT
        viewModel.select(song: TestData.song1)

        // ASSERT
        #expect(container.capturedSongList === container.recentListSpy)
        #expect(container.capturedSelectedSong == TestData.song1)
        let presented = try #require(viewModel.player.presented as? CompleteSongPlayerViewModelStub)
        #expect(presented === container.completeSongPlayerViewModelStub)
    }

    @Test func select_usesSearchListQueueWhenSearchListIsShowingAndPresentsPlayer() throws {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        viewModel.handleSearchBar(focused: true)

        // ACT
        viewModel.select(song: TestData.song2)

        // ASSERT
        #expect(container.capturedSongList === container.searchListSpy)
        #expect(container.capturedSelectedSong == TestData.song2)
        let presented = try #require(viewModel.player.presented as? CompleteSongPlayerViewModelStub)
        #expect(presented === container.completeSongPlayerViewModelStub)
    }

    @Test func selectAlbum_presentsAlbumViewModelWhenSongHasAlbum() throws {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        var song = TestData.song1
        song.album = TestData.album

        // ACT
        viewModel.selectAlbum(of: song)

        // ASSERT
        #expect(container.capturedAlbumId == TestData.album.id)
        let presented = try #require(viewModel.album.presented as? AlbumViewModelStub)
        #expect(presented === container.albumViewModelStub)
    }

    @Test func handleSearchBar_notFocusedRefreshesRecentListWhenPlayedSongChangedTopRecentSong() async {
        // ARRANGE
        let container = IoCContainerStub()
        container.recentListSpy.items = [TestData.song1]
        let interactionEvent = Event<SongInteraction>()
        let viewModel = makeViewModel(
            interactionService: .init(
                songMarkedPlayedEvent: interactionEvent,
                markPlayed: { _ in },
                listPlayedSongs: { _ in
                    Pagination<NullPaginationParams>.Page(entries: [], pagination: .first(limit: 10))
                }
            ),
            container: container
        )
        viewModel.onAppear()
        await busyWait { container.recentListSpy.refreshCallCount == 1 }
        viewModel.handleSearchBar(focused: true)
        await busyWaitAsync {
            let observerCount = await interactionEvent.observerCount
            return observerCount > 0
        }

        // ACT
        await interactionEvent.emit(.init(song: TestData.song2, lastPlayedAt: .now))
        try? await Task.sleep(nanoseconds: 100) // required, because the event observer is triggered async'ly
        viewModel.handleSearchBar(focused: false)
        await busyWait { container.recentListSpy.refreshCallCount == 2 }

        // ASSERT
        #expect(container.recentListSpy.refreshCallCount == 2)
        #expect(container.recentListSpy.loadFirstPageIfNeededCallCount == 0)
    }

    private func makeViewModel(
        interactionService: InteractionService = .init(
            songMarkedPlayedEvent: Event<SongInteraction>(),
            markPlayed: { _ in },
            listPlayedSongs: { _ in
                Pagination<NullPaginationParams>.Page(entries: [], pagination: .first(limit: 10))
            }
        ),
        songService: SongSearchService = .init(
            search: { _ in
                SongSearchPage(entries: [], pagination: .first(params: .init(searchTerm: ""), limit: 10))
            }
        ),
        container: IoCContainerStub
    ) -> SongListViewModelImpl {
        SongListViewModelImpl(
            interactionService: interactionService,
            songService: songService,
            container: container
        )
    }
}

@MainActor
private final class IoCContainerStub: IoCContainer {
    let recentListSpy = PaginatedListViewModelSpy<Song, NullPaginationParams>()
    let searchListSpy = PaginatedListViewModelSpy<Song, SongSearchParams>()
    let completeSongPlayerViewModelStub = CompleteSongPlayerViewModelStub()
    let albumViewModelStub = AlbumViewModelStub()

    private let playerPresentation = PresentationViewModelImpl<any CompleteSongPlayerViewModel>()
    private let albumPresentation = PresentationViewModelImpl<any AlbumViewModel>()

    private(set) var capturedSongList: (any PaginatedListViewModel<Song>)?
    private(set) var capturedSelectedSong: Song?
    private(set) var capturedAlbumId: String?

    func completeSongPlayerViewModel(
        songList: any PaginatedListViewModel<Song>,
        selectedSong: Song
    ) -> any CompleteSongPlayerViewModel {
        capturedSongList = songList
        capturedSelectedSong = selectedSong
        return completeSongPlayerViewModelStub
    }

    func albumViewModel(albumId: String) -> any AlbumViewModel {
        capturedAlbumId = albumId
        return albumViewModelStub
    }

    func presentationViewModel<T>() -> any PresentationViewModel<T> {
        if let playerPresentation = playerPresentation as? any PresentationViewModel<T> {
            return playerPresentation
        }

        if let albumPresentation = albumPresentation as? any PresentationViewModel<T> {
            return albumPresentation
        }

        return PresentationViewModelImpl<T>()
    }

    func paginatedListViewModel<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>(
        ofKind kind: PaginatedListViewModelDependencyKind<Item, PaginationParams>
    ) -> any PaginatedListViewModel<Item> {
        if Item.self == Song.self,
           PaginationParams.self == NullPaginationParams.self,
           let recentList = recentListSpy as? any PaginatedListViewModel<Item> {
            return recentList
        }

        if Item.self == Song.self,
           PaginationParams.self == SongSearchParams.self,
           let searchList = searchListSpy as? any PaginatedListViewModel<Item> {
            return searchList
        }

        switch kind {
        case let .dynamic(fetch):
            return PaginatedListViewModelImpl(fetch: fetch)
        case .static:
            fatalError("Unexpected static paginated list request in SongListViewModelImplTests")
        }
    }
}

@MainActor
private final class PaginatedListViewModelSpy<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>: PaginatedListViewModel {
    var items: [Item] = []
    var loadState: PaginatedListLoadState = .idle
    var hasMore = false
    var latestResult: Pagination<PaginationParams>.Page<Item>?
    var pageLoadedEvent = Event<Result<[Item], Error>>()

    private(set) var loadFirstPageIfNeededCallCount = 0
    private(set) var loadNextPageCallCount = 0
    private(set) var refreshCallCount = 0
    private(set) var interactWithErrorCalls: [Bool] = []
    private(set) var resetCallCount = 0

    func loadFirstPageIfNeeded() {
        loadFirstPageIfNeededCallCount += 1
    }

    func loadNextPage() {
        loadNextPageCallCount += 1
    }

    func refresh() async {
        refreshCallCount += 1
    }

    func interactWithError(shouldRetry: Bool) {
        interactWithErrorCalls.append(shouldRetry)
    }

    func reset() {
        resetCallCount += 1
    }
}

@MainActor
private final class CompleteSongPlayerViewModelStub: CompleteSongPlayerViewModel {
    let actualPlayer: any FocusedSongPlayerViewModel = FocusedSongPlayerViewModelStub()
    let songList: any PaginatedListViewModel<Song> = PaginatedListViewModelImpl<Song, NullPaginationParams>(staticItems: [])
    var album: any PresentationViewModel<any AlbumViewModel> = PresentationViewModelImpl<any AlbumViewModel>()

    func select(song: Song) {
    }

    func selectAlbum(of song: Song) {
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
    var album: any PresentationViewModel<any AlbumViewModel> = PresentationViewModelImpl<any AlbumViewModel>()

    func onAppear() {
    }

    func onDisappear() {
    }

    func selectAlbum(of song: Song) {
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

@MainActor
@Observable
private final class AlbumViewModelStub: AlbumViewModel {
    var album: ActionStatus<Album, UserFacingError> = .none
    var player: any PresentationViewModel<any CompleteSongPlayerViewModel> = PresentationViewModelImpl<any CompleteSongPlayerViewModel>()

    func onAppear() {
    }

    func onDisappear() {
    }

    func loadAlbum() {
    }

    func select(song: Song) {
    }
}
