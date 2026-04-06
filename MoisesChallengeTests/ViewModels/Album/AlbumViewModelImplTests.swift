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

    @Test func select_setsObservableSelectedSong() {
        // ARRANGE
        let viewModel = makeViewModel(service: AlbumSearchService(get: { _ in TestData.album }))
        viewModel.album = .success(TestData.album)

        // ACT
        viewModel.select(song: TestData.song2)

        // ASSERT
        #expect(viewModel.observableSelectedSong?.value == TestData.song2)
    }

    @Test func select_setsObservableSelectedSongEvenWhenAlbumDidNotLoadSuccessfully() {
        // ARRANGE
        let viewModel = makeViewModel(service: AlbumSearchService(get: { _ in TestData.album }))
        viewModel.album = .failure(InvalidDataError().userFacingError)

        // ACT
        viewModel.select(song: TestData.song1)

        // ASSERT
        #expect(viewModel.observableSelectedSong?.value == TestData.song1)
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
}
