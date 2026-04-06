//
//  AlbumViewModelImplTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 04/04/26.
//

import Foundation
import Observation
import Testing
@testable import MoisesChallenge

@MainActor
struct AlbumViewModelImplTests {

    @Test func onAppear_loadsAlbumWhenAlbumWasNotLoadedYet() async {
        // ARRANGE
        let service = AlbumServiceSpy(results: [.success(TestData.album)])
        let viewModel = makeViewModel(service: makeService(spy: service), appCoordinator: AppCoordinatorSpy())

        // ACT
        viewModel.onAppear()
        await busyWait(until: {
            if case .success = viewModel.album { return true }
            return false
        })

        // ASSERT
        #expect(viewModel.album == .success(TestData.album))
        #expect(await service.requestedAlbumIds() == [TestData.album.id])
    }

    @Test func onAppear_doesNotReloadAlbumWhenAlbumWasAlreadyLoaded() async {
        // ARRANGE
        let service = AlbumServiceSpy(results: [.success(TestData.album)])
        let viewModel = makeViewModel(service: makeService(spy: service), appCoordinator: AppCoordinatorSpy())

        // ACT
        viewModel.onAppear()
        await busyWait(until: {
            if case .success = viewModel.album { return true }
            return false
        })
        viewModel.onAppear()

        // ASSERT
        #expect(viewModel.album == .success(TestData.album))
        #expect(await service.requestedAlbumIds() == [TestData.album.id])
    }

    @Test func loadAlbum_setsAlbumDetailsWhenRequestSucceeds() async {
        // ARRANGE
        let service = AlbumServiceSpy(results: [.success(TestData.album)])
        let viewModel = makeViewModel(service: makeService(spy: service), appCoordinator: AppCoordinatorSpy())

        // ACT
        viewModel.loadAlbum()
        await busyWait(until: {
            if case .success = viewModel.album { return true }
            return false
        })

        // ASSERT
        #expect(viewModel.album == .success(TestData.album))
        #expect(await service.requestedAlbumIds() == [TestData.album.id])
    }

    @Test func loadAlbum_setsFailureWhenRequestFails() async {
        // ARRANGE
        let error = InvalidDataError()
        let service = AlbumServiceSpy(results: [.failure(error)])
        let viewModel = makeViewModel(service: makeService(spy: service), appCoordinator: AppCoordinatorSpy())

        // ACT
        viewModel.loadAlbum()
        await busyWait(until: {
            if case .failure = viewModel.album { return true }
            return false
        })

        // ASSERT
        #expect(viewModel.album == .failure(error.userFacingError))
        #expect(await service.requestedAlbumIds() == [TestData.album.id])
    }

    @Test func loadAlbum_retriesLoadingAlbumAfterFailure() async {
        // ARRANGE
        let service = AlbumServiceSpy(results: [.failure(InvalidDataError()), .success(TestData.album)])
        let viewModel = makeViewModel(service: makeService(spy: service), appCoordinator: AppCoordinatorSpy())

        // ACT
        viewModel.loadAlbum()
        await busyWait(until: {
            if case .failure = viewModel.album { return true }
            return false
        })
        viewModel.loadAlbum()
        await busyWait(until: {
            if case .success = viewModel.album { return true }
            return false
        })

        // ASSERT
        #expect(viewModel.album == .success(TestData.album))
        #expect(await service.requestedAlbumIds() == [TestData.album.id, TestData.album.id])
    }

    @Test func select_requestsSongPlaybackStartingFromSelectedSong() async throws {
        // ARRANGE
        let container = IoCContainerStub()
        let appCoordinator = AppCoordinatorSpy()
        let viewModel = AlbumViewModelImpl(
            albumId: TestData.album.id,
            service: AlbumSearchService(get: { _ in TestData.album }),
            container: container,
            appCoordinator: appCoordinator
        )
        viewModel.album = .success(TestData.album)

        // ACT
        viewModel.select(song: TestData.song2)

        // ASSERT
        let songList = try #require(appCoordinator.capturedSongList)
        songList.loadFirstPageIfNeeded()
        await busyWait { songList.items == [TestData.song1, TestData.song2] }
        #expect(songList.items == [TestData.song1, TestData.song2])
        #expect(appCoordinator.capturedSelectedSong == TestData.song2)
    }

    @Test func select_doesNothingWhenAlbumDidNotLoadSuccessfully() {
        // ARRANGE
        let container = IoCContainerStub()
        let appCoordinator = AppCoordinatorSpy()
        let viewModel = AlbumViewModelImpl(
            albumId: TestData.album.id,
            service: AlbumSearchService(get: { _ in TestData.album }),
            container: container,
            appCoordinator: appCoordinator
        )
        viewModel.album = .failure(InvalidDataError().userFacingError)

        // ACT
        viewModel.select(song: TestData.song1)

        // ASSERT
        #expect(appCoordinator.capturedSongList == nil)
        #expect(appCoordinator.capturedSelectedSong == nil)
    }

    private func makeViewModel(
        service: AlbumSearchService,
        appCoordinator: any AppCoordinator
    ) -> AlbumViewModelImpl {
        AlbumViewModelImpl(
            albumId: TestData.album.id,
            service: service,
            container: IoCContainerStub(),
            appCoordinator: appCoordinator
        )
    }

    private func makeService(spy: AlbumServiceSpy) -> AlbumSearchService {
        AlbumSearchService(get: { albumId in
            try await spy.get(albumId)
        })
    }
}

private actor AlbumServiceSpy {
    private var results: [Result<Album, Error>]
    private var albumIds: [String] = []

    init(results: [Result<Album, Error>]) {
        self.results = results
    }

    func get(_ albumId: String) throws -> Album {
        albumIds.append(albumId)

        guard !results.isEmpty else {
            throw InvalidDataError()
        }

        return try results.removeFirst().get()
    }

    func requestedAlbumIds() -> [String] {
        albumIds
    }
}

@MainActor
private final class IoCContainerStub: IoCContainer {
}

@MainActor
private final class AppCoordinatorSpy: AppCoordinator {
    private(set) var capturedSongList: (any PaginatedListViewModel<Song>)?
    private(set) var capturedSelectedSong: Song?

    func play(song: Song, from songList: any PaginatedListViewModel<Song>) {
        capturedSongList = songList
        capturedSelectedSong = song
    }

    func showAlbum(albumId: String) {
    }

    func presentPlayer() {
    }

    func dismissPlayer() {
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
