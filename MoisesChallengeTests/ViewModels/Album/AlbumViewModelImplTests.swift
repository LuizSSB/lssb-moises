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
        let viewModel = makeViewModel(service: makeService(spy: service))

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
        let viewModel = makeViewModel(service: makeService(spy: service))

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
        let viewModel = makeViewModel(service: makeService(spy: service))

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
        let viewModel = makeViewModel(service: makeService(spy: service))

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
        let viewModel = makeViewModel(service: makeService(spy: service))

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

    @Test func select_presentsSongPlayerStartingFromSelectedSong() async throws {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = AlbumViewModelImpl(
            albumId: TestData.album.id,
            service: AlbumSearchService(get: { _ in TestData.album }),
            container: container
        )
        viewModel.album = .success(TestData.album)

        // ACT
        viewModel.select(song: TestData.song2)

        // ASSERT
        let queue = try #require(container.capturedQueue)
        #expect(queue.currentItem == TestData.song2)
        #expect(queue.has(.previous))
        #expect(!queue.has(.next))
        #expect(viewModel.player.presented === container.songPlayerViewModelStub)
    }

    @Test func select_doesNothingWhenAlbumDidNotLoadSuccessfully() {
        // ARRANGE
        let container = IoCContainerStub()
        let viewModel = AlbumViewModelImpl(
            albumId: TestData.album.id,
            service: AlbumSearchService(get: { _ in TestData.album }),
            container: container
        )
        viewModel.album = .failure(InvalidDataError().userFacingError)

        // ACT
        viewModel.select(song: TestData.song1)

        // ASSERT
        #expect(container.capturedQueue == nil)
        #expect(viewModel.player.presented == nil)
    }

    private func makeViewModel(service: AlbumSearchService) -> AlbumViewModelImpl {
        AlbumViewModelImpl(
            albumId: TestData.album.id,
            service: service,
            container: IoCContainerStub()
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
    let songPlayerViewModelStub = SongPlayerViewModelStub()
    private(set) var capturedQueue: (any PlaybackQueue<Song>)?

    func focusedSongPlayerViewModel(queue: any PlaybackQueue<Song>) -> any FocusedSongPlayerViewModel {
        capturedQueue = queue
        return songPlayerViewModelStub
    }

    func presentationViewModel<T>() -> any PresentationViewModel<T> {
        return PresentationViewModelImpl<T>()
    }
}

@MainActor
@Observable
private final class SongPlayerViewModelStub: FocusedSongPlayerViewModel {
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
