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

    @Test func submitSearch_retriesWhenCurrentQueryIsUnchangedButSearchIsInErrorState() async {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        viewModel.handleSearchBar(focused: true)
        viewModel.workingSearchQuery = "query"
        viewModel.submitSearch()
        await busyWait { container.searchListSpy.refreshCallCount == 1 }
        container.searchListSpy.loadState = .error(InvalidDataError().userFacingError)

        // ACT
        viewModel.workingSearchQuery = "query"
        viewModel.submitSearch()

        // ASSERT
        #expect(viewModel.currentQuery == "query")
        #expect(container.searchListSpy.refreshCallCount == 1)
        #expect(container.searchListSpy.interactWithErrorCalls == [true])
    }

    @Test func select_setsObservableSelectedSongFromRecentListWhenSearchListIsNotShowing() {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)

        // ACT
        viewModel.select(song: TestData.song1)

        // ASSERT
        #expect((viewModel.currentList as? PaginatedListViewModelSpy<Song, NullPaginationParams>) === container.recentListSpy)
        #expect(viewModel.observableSelectedSong?.value == TestData.song1)
    }

    @Test func select_setsObservableSelectedSongFromSearchListWhenSearchListIsShowing() {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        viewModel.handleSearchBar(focused: true)

        // ACT
        viewModel.select(song: TestData.song2)

        // ASSERT
        #expect((viewModel.currentList as? PaginatedListViewModelSpy<Song, SongSearchParams>) === container.searchListSpy)
        #expect(viewModel.observableSelectedSong?.value == TestData.song2)
    }

    @Test func selectAlbum_setsObservableSelectedAlbumIdWhenSongHasAlbum() {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = makeViewModel(container: container)
        var song = TestData.song1
        song.album = TestData.album

        // ACT
        viewModel.selectAlbum(of: song)

        // ASSERT
        #expect(viewModel.observableSelectedAlbumId?.value == TestData.album.id)
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
        try? await Task.sleep(nanoseconds: 100)
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
        container: IoCContainerStub
    ) -> SongListViewModelImpl {
        SongListViewModelImpl(
            interactionService: interactionService,
            songService: container.songSearchService(),
            container: container
        )
    }
}

@MainActor
private final class IoCContainerStub: IoCContainer {
    let recentListSpy = PaginatedListViewModelSpy<Song, NullPaginationParams>()
    let searchListSpy = PaginatedListViewModelSpy<Song, SongSearchParams>()

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
@Observable
private final class PaginatedListViewModelSpy<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable>: PaginatedListViewModel {
    var items: [Item] = []
    var loadState: PaginatedListLoadState = .idle
    var hasMore = false
    var latestResult: Pagination<PaginationParams>.Page<Item>?
    var lastLoadResult: Result<[Item], Error>?

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
