//
//  SongPlayerViewModelImplTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 04/04/26.
//

@testable import MoisesChallenge
import Observation
import Testing

@MainActor
struct SongPlayerViewModelImplTests {
    @Test func onAppear_loadsCurrentSongFromQueue() {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1, TestData.song2], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let interactionStore = PlayedSongsStore()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController,
            interactionStore: interactionStore
        )

        // ACT
        viewModel.onAppear()

        // ASSERT
        #expect(viewModel.currentSong == TestData.song1)
        #expect(viewModel.playbackState == .loading)
        #expect(playbackController.loadedSongs == [TestData.song1])
    }

    @Test func readyToPlay_startsPlaybackAndMarksCurrentSongPlayed() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let interactionStore = PlayedSongsStore()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController,
            interactionStore: interactionStore
        )

        // ACT
        viewModel.onAppear()
        playbackController.observableEvent = .readyToPlay
        await busyWait { viewModel.playbackState == .playing }
        await busyWaitAsync { await interactionStore.songs == [TestData.song1] }

        // ASSERT
        #expect(viewModel.playbackState == .playing)
        #expect(await interactionStore.songs == [TestData.song1])
    }

    @Test func progress_updatesElapsedDurationAndFraction() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()

        // ACT
        playbackController.observableEvent = .progress(elapsed: 30, duration: 120)
        await busyWait { viewModel.duration == 120 }

        // ASSERT
        #expect(viewModel.elapsed == 30)
        #expect(viewModel.duration == 120)
        #expect(viewModel.progress == 0.25)
    }

    @Test func togglePlayPause_pausesWhenPlaybackIsPlaying() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()
        playbackController.observableEvent = .readyToPlay
        await busyWait { viewModel.playbackState == .playing }

        // ACT
        viewModel.togglePlayPause()

        // ASSERT
        #expect(viewModel.playbackState == .paused)
        #expect(playbackController.pauseCallCount == 1)
    }

    @Test func togglePlayPause_resumesPlaybackWhenPlaybackIsPaused() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()
        playbackController.observableEvent = .readyToPlay
        await busyWait { viewModel.playbackState == .playing }
        viewModel.togglePlayPause()

        // ACT
        viewModel.togglePlayPause()

        // ASSERT
        #expect(viewModel.playbackState == .playing)
        #expect(playbackController.playCallCount == 1)
    }

    @Test func toggleRepeatMode_cyclesThroughAllModes() {
        // ARRANGE
        let viewModel = makeViewModel(
            queue: PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0),
            playbackController: SongPlaybackControllerStub()
        )

        // ACT
        viewModel.toggleRepeatMode()

        // ASSERT
        #expect(viewModel.repeatMode == .current)

        // ACT
        viewModel.toggleRepeatMode()

        // ASSERT
        #expect(viewModel.repeatMode == .all)

        // ACT
        viewModel.toggleRepeatMode()

        // ASSERT
        #expect(viewModel.repeatMode == .none)
    }

    @Test func move_pausesPlaybackWhenAdvancingQueueFails() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0)
        queue.hasNextOverride = true
        queue.moveError = InvalidDataError()
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()
        playbackController.observableEvent = .readyToPlay
        await busyWait { viewModel.playbackState == .playing }
        let stopCallCountBeforeFailure = playbackController.stopCallCount

        // ACT
        viewModel.move(to: .next)
        await busyWait { viewModel.playbackState == .paused }

        // ASSERT
        #expect(queue.moveCallNames == ["next"])
        #expect(viewModel.playbackState == .paused)
        #expect(playbackController.stopCallCount > stopCallCountBeforeFailure)
    }

    @Test func didFinishPlaying_movesToNextSongWhenRepeatModeIsNoneAndQueueHasNext() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1, TestData.song2], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()

        // ACT
        playbackController.observableEvent = .didFinishPlaying
        await busyWait { viewModel.currentSong == TestData.song2 }

        // ASSERT
        #expect(queue.moveCallNames == ["next"])
        #expect(viewModel.currentSong == TestData.song2)
        #expect(viewModel.playbackState == .loading)
    }

    @Test func didFinishPlaying_seeksToStartWhenRepeatModeIsNoneAndQueueHasNoNext() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()
        playbackController.observableEvent = .readyToPlay
        await busyWait { viewModel.playbackState == .playing }

        // ACT
        playbackController.observableEvent = .didFinishPlaying
        await busyWait { playbackController.seekCalls == [0] }

        // ASSERT
        #expect(viewModel.playbackState == .paused)
        #expect(playbackController.seekCalls == [0])
    }

    @Test func didFinishPlaying_restartsCurrentSongWhenRepeatModeIsCurrent() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()
        viewModel.toggleRepeatMode()

        // ACT
        playbackController.observableEvent = .didFinishPlaying
        await busyWait { playbackController.restartCallCount == 1 }

        // ASSERT
        #expect(viewModel.repeatMode == .current)
        #expect(viewModel.playbackState == .playing)
        #expect(playbackController.restartCallCount == 1)
        #expect(viewModel.elapsed == 0)
        #expect(viewModel.progress == 0)
    }

    @Test func didFinishPlaying_movesToFirstSongWhenRepeatModeIsAllAndQueueEndsAwayFromFirst() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1, TestData.song2], currentIndex: 1)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()
        viewModel.toggleRepeatMode()
        viewModel.toggleRepeatMode()

        // ACT
        playbackController.observableEvent = .didFinishPlaying
        await busyWait { viewModel.currentSong == TestData.song1 }

        // ASSERT
        #expect(viewModel.repeatMode == .all)
        #expect(queue.currentIndex == 0)
        #expect(viewModel.currentSong == TestData.song1)
        #expect(viewModel.playbackState == .loading)
    }

    @Test func failed_movesToNextSongWhenCurrentSongFailsToLoad() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1, TestData.song2], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()

        // ACT
        playbackController.observableEvent = .failed
        await busyWait { viewModel.currentSong == TestData.song2 }

        // ASSERT
        #expect(queue.moveCallNames == ["next"])
        #expect(viewModel.currentSong == TestData.song2)
        #expect(viewModel.playbackState == .loading)
    }

    @Test func failed_pausesPlaybackWhenCurrentSongFailsToLoadAndQueueHasNoNext() async {
        // ARRANGE
        let queue = PlaybackQueueStub(songs: [TestData.song1], currentIndex: 0)
        let playbackController = SongPlaybackControllerStub()
        let viewModel = makeViewModel(
            queue: queue,
            playbackController: playbackController
        )
        viewModel.onAppear()
        let stopCallCountBeforeFailure = playbackController.stopCallCount

        // ACT
        playbackController.observableEvent = .failed
        await busyWait { viewModel.playbackState == .paused }

        // ASSERT
        #expect(viewModel.playbackState == .paused)
        #expect(queue.moveCalls.isEmpty)
        #expect(playbackController.stopCallCount > stopCallCountBeforeFailure)
    }

    private func makeViewModel(
        queue: PlaybackQueueStub,
        playbackController: SongPlaybackControllerStub,
        interactionStore: PlayedSongsStore = PlayedSongsStore()
    ) -> FocusedSongPlayerViewModelImpl {
        FocusedSongPlayerViewModelImpl(
            queue: queue,
            playbackController: playbackController,
            interactionService: .init(
                songMarkedPlayedEvent: Event<SongInteraction>(),
                markPlayed: { song in
                    await interactionStore.append(song)
                },
                listPlayedSongs: { _ in
                    .init(entries: [], pagination: .first())
                }
            )
        )
    }
}

@MainActor
@Observable
private final class PlaybackQueueStub: PlaybackQueue {
    private let songs: [Song]
    private var storedCurrentIndex: Int?
    var currentItem: Song?

    var currentIndex: Int? {
        get {
            storedCurrentIndex
        }
        set {
            guard let newValue else {
                storedCurrentIndex = nil
                currentItem = nil
                return
            }

            guard songs.indices.contains(newValue) else { return }
            guard newValue != storedCurrentIndex else { return }

            storedCurrentIndex = newValue
            currentItem = songs[newValue]
        }
    }

    var hasNextOverride: Bool?
    var hasPreviousOverride: Bool?
    var isLoadingNext = false
    var isLoadingPrevious = false
    var moveError: Error?
    private(set) var moveCalls: [PlaybackQueueDirection] = []
    var moveCallNames: [String] {
        moveCalls.map {
            switch $0 {
            case .previous: "previous"
            case .next: "next"
            }
        }
    }

    init(songs: [Song], currentIndex: Int?) {
        self.songs = songs
        storedCurrentIndex = currentIndex
        currentItem = currentIndex.flatMap { songs.indices.contains($0) ? songs[$0] : nil }
    }

    func isLoading(_ direction: PlaybackQueueDirection) -> Bool {
        switch direction {
        case .previous:
            isLoadingPrevious
        case .next:
            isLoadingNext
        }
    }

    func has(_ direction: PlaybackQueueDirection) -> Bool {
        switch direction {
        case .previous:
            if let hasPreviousOverride {
                return hasPreviousOverride
            }
            guard let storedCurrentIndex else { return false }
            return storedCurrentIndex > 0

        case .next:
            if let hasNextOverride {
                return hasNextOverride
            }
            guard let storedCurrentIndex else { return false }
            return storedCurrentIndex < songs.count - 1
        }
    }

    func move(to direction: PlaybackQueueDirection) async throws {
        moveCalls.append(direction)

        if let moveError {
            throw moveError
        }

        switch direction {
        case .previous:
            guard let storedCurrentIndex, storedCurrentIndex > 0 else { return }
            currentIndex = storedCurrentIndex - 1

        case .next:
            guard let storedCurrentIndex, storedCurrentIndex < songs.count - 1 else { return }
            currentIndex = storedCurrentIndex + 1
        }
    }
}

@MainActor
@Observable
private final class SongPlaybackControllerStub: SongPlaybackController {
    var observableEvent: SongPlaybackControllerEvent?

    private(set) var loadedSongs: [Song] = []
    private(set) var playCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var restartCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var seekCalls: [Double] = []

    func load(_ song: Song) {
        loadedSongs.append(song)
    }

    func play() {
        playCallCount += 1
    }

    func pause() {
        pauseCallCount += 1
    }

    func seek(to fraction: Double) {
        seekCalls.append(fraction)
    }

    func restart() {
        restartCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }
}

private actor PlayedSongsStore {
    private(set) var songs: [Song] = []

    func append(_ song: Song) {
        songs.append(song)
    }
}
