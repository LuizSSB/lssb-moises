//
//  PaginatedListViewModelImplTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 04/04/26.
//

import Testing
@testable import MoisesChallenge

@MainActor
struct PaginatedListViewModelImplTests {
    typealias Page = Pagination<NullPaginationParams>.Page<Int>

    @Test func init_startsIdleWithNoItemsAndNoLatestResult() {
        // ARRANGE
        let viewModel = makeViewModel(with: FetchStub([]))

        // ACT

        // ASSERT
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.loadState == .idle)
        #expect(!viewModel.hasMore)
        #expect(viewModel.latestResult == nil)
    }

    @Test func hasMore_tracksWhetherLatestPageCanLoadAnotherPage() async throws {
        // ARRANGE
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))),
            .success(Page(entries: [3], pagination: .init(offset: 2, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)

        let firstLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccessEntries(try #require(await firstLoad.value))

        // ASSERT
        #expect(viewModel.hasMore)

        let nextLoad = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        viewModel.loadNextPage()
        _ = try requireSuccessEntries(try #require(await nextLoad.value))

        // ASSERT
        #expect(!viewModel.hasMore)
    }

    @Test func loadFirstPageIfNeeded_loadsFirstPageAndStoresFetchedEntries() async throws {
        // ARRANGE
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)
        let result = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        viewModel.loadFirstPageIfNeeded()

        let entries = try requireSuccessEntries(try #require(await result.value))

        // ASSERT
        #expect(entries == [1, 2])
        #expect(viewModel.items == [1, 2])
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.latestResult == Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2)))
        #expect(viewModel.hasMore)
        #expect(await stub.requestedPages() == [nil])
    }

    @Test func loadFirstPageIfNeeded_setsEmptyWhenFetchedPageHasNoEntries() async throws {
        // ARRANGE
        let stub = FetchStub([
            .success(Page(entries: [], pagination: .init(offset: 0, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)
        let result = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        viewModel.loadFirstPageIfNeeded()

        let entries = try requireSuccessEntries(try #require(await result.value))

        // ASSERT
        #expect(entries.isEmpty)
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.loadState == .empty)
        #expect(!viewModel.hasMore)
        #expect(viewModel.latestResult == Page(entries: [], pagination: .init(offset: 0, limit: 2)))
    }

    @Test func loadNextPage_appendsEntriesFromFollowingPage() async throws {
        // ARRANGE
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))),
            .success(Page(entries: [3], pagination: .init(offset: 2, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)

        let firstLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccessEntries(try #require(await firstLoad.value))

        let nextLoad = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        viewModel.loadNextPage()

        let entries = try requireSuccessEntries(try #require(await nextLoad.value))

        // ASSERT
        #expect(entries == [3])
        #expect(viewModel.items == [1, 2, 3])
        #expect(viewModel.loadState == .loaded)
        #expect(!viewModel.hasMore)
        #expect(viewModel.latestResult == Page(entries: [3], pagination: .init(offset: 2, limit: 2)))
        #expect(
            await stub.requestedPages() == [
                nil,
                Pagination(offset: 2, limit: 2)
            ]
        )
    }

    @Test func refresh_replacesItemsAndLoadsNextPageWhenListAlreadyHadEntries() async throws {
        // ARRANGE
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))),
            .success(Page(entries: [10, 11], pagination: .init(offset: 0, limit: 2))),
            .success(Page(entries: [12], pagination: .init(offset: 2, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)

        let initialLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccessEntries(try #require(await initialLoad.value))

        let refreshEvents = await readPageLoadedEvents(from: viewModel, count: 2)

        // ACT
        await viewModel.refresh()

        let events = await refreshEvents.value

        // ASSERT
        #expect(events.count == 2)
        #expect(try requireSuccessEntries(events[0]) == [10, 11])
        #expect(try requireSuccessEntries(events[1]) == [12])
        #expect(viewModel.items == [10, 11, 12])
        #expect(viewModel.loadState == .loaded)
        #expect(!viewModel.hasMore)
        #expect(viewModel.latestResult == Page(entries: [12], pagination: .init(offset: 2, limit: 2)))
        #expect(
            await stub.requestedPages() == [
                nil,
                nil,
                Pagination(offset: 2, limit: 2)
            ]
        )
    }

    @Test func loadFirstPageIfNeeded_setsErrorStateAndEmitsFailureWhenFetchFails() async throws {
        // ARRANGE
        let stub = FetchStub([
            .failure(InvalidDataError())
        ])
        let viewModel = makeViewModel(with: stub)
        let result = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        viewModel.loadFirstPageIfNeeded()

        let failure = try #require(await result.value)

        // ASSERT
        switch failure {
        case .success:
            Issue.record("Expected the first page load to fail.")
        case .failure(let error):
            #expect(error is InvalidDataError)
        }

        #expect(viewModel.items.isEmpty)
        #expect(!viewModel.hasMore)
        #expect(viewModel.latestResult == nil)
        #expect(viewModel.loadState == .error(InvalidDataError().userFacingError))
    }

    @Test func interactWithError_retriesFailedFirstPageLoadWhenRequested() async throws {
        // ARRANGE
        let stub = FetchStub([
            .failure(InvalidDataError()),
            .success(Page(entries: [1], pagination: .init(offset: 0, limit: 1)))
        ])
        let viewModel = makeViewModel(with: stub)

        let failedLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try #require(await failedLoad.value)

        let retriedLoad = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        viewModel.interactWithError(shouldRetry: true)

        let entries = try requireSuccessEntries(try #require(await retriedLoad.value))

        // ASSERT
        #expect(entries == [1])
        #expect(viewModel.items == [1])
        #expect(viewModel.loadState == .loaded)
        #expect(await stub.requestedPages() == [nil, nil])
    }

    @Test func interactWithError_retriesFailedNextPageLoadWhenRequested() async throws {
        // ARRANGE
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))),
            .failure(InvalidDataError()),
            .success(Page(entries: [3], pagination: .init(offset: 2, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)

        let initialLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccessEntries(try #require(await initialLoad.value))

        let failedNextLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadNextPage()
        _ = try #require(await failedNextLoad.value)

        let retriedNextLoad = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        viewModel.interactWithError(shouldRetry: true)

        let entries = try requireSuccessEntries(try #require(await retriedNextLoad.value))

        // ASSERT
        #expect(entries == [3])
        #expect(viewModel.items == [1, 2, 3])
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.latestResult == Page(entries: [3], pagination: .init(offset: 2, limit: 2)))
        #expect(
            await stub.requestedPages() == [
                nil,
                Pagination(offset: 2, limit: 2),
                Pagination(offset: 2, limit: 2)
            ]
        )
    }

    @Test func interactWithError_restoresIdleStateWhenAbandoningFailedFirstPageLoad() async throws {
        // ARRANGE
        let stub = FetchStub([
            .failure(InvalidDataError())
        ])
        let viewModel = makeViewModel(with: stub)
        let result = await readNextPageLoadedEvent(from: viewModel)

        viewModel.loadFirstPageIfNeeded()
        _ = try #require(await result.value)

        // ACT
        viewModel.interactWithError(shouldRetry: false)

        // ASSERT
        #expect(viewModel.loadState == .idle)
        #expect(viewModel.items.isEmpty)
    }

    @Test func interactWithError_restoresLoadedStateWhenAbandoningFailedNextPageLoad() async throws {
        // ARRANGE
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))),
            .failure(InvalidDataError())
        ])
        let viewModel = makeViewModel(with: stub)

        let initialLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccessEntries(try #require(await initialLoad.value))

        let nextLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadNextPage()
        _ = try #require(await nextLoad.value)

        // ACT
        viewModel.interactWithError(shouldRetry: false)

        // ASSERT
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.items == [1, 2])
        #expect(viewModel.hasMore)
        #expect(viewModel.latestResult == Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2)))
    }

    @Test func refresh_setsErrorStateAndKeepsCurrentItemsWhenFetchFails() async throws {
        // ARRANGE
        let initialPage = Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))
        let stub = FetchStub([
            .success(initialPage),
            .failure(InvalidDataError())
        ])
        let viewModel = makeViewModel(with: stub)

        let initialLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccessEntries(try #require(await initialLoad.value))

        let failedRefresh = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        await viewModel.refresh()

        let refreshResult = try #require(await failedRefresh.value)

        // ASSERT
        switch refreshResult {
        case .success:
            Issue.record("Expected refreshing the list to fail.")
        case .failure(let error):
            #expect(error is InvalidDataError)
        }
        #expect(viewModel.items == [1, 2])
        #expect(viewModel.hasMore)
        #expect(viewModel.latestResult == initialPage)
        #expect(viewModel.loadState == .error(InvalidDataError().userFacingError))
    }

    @Test func interactWithError_restoresLoadedStateWhenAbandoningFailedRefresh() async throws {
        // ARRANGE
        let initialPage = Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))
        let stub = FetchStub([
            .success(initialPage),
            .failure(InvalidDataError())
        ])
        let viewModel = makeViewModel(with: stub)

        let initialLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccessEntries(try #require(await initialLoad.value))

        let failedRefresh = await readNextPageLoadedEvent(from: viewModel)
        await viewModel.refresh()
        _ = try #require(await failedRefresh.value)

        // ACT
        viewModel.interactWithError(shouldRetry: false)

        // ASSERT
        #expect(viewModel.items == [1, 2])
        #expect(viewModel.hasMore)
        #expect(viewModel.latestResult == initialPage)
        #expect(viewModel.loadState == .loaded)
    }

    @Test func interactWithError_retriesFailedRefreshWhenRequested() async throws {
        // ARRANGE
        let initialPage = Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))
        let refreshedPage = Page(entries: [10, 11], pagination: .init(offset: 0, limit: 2))
        let stub = FetchStub([
            .success(initialPage),
            .failure(InvalidDataError()),
            .success(refreshedPage)
        ])
        let viewModel = makeViewModel(with: stub)

        let initialLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccessEntries(try #require(await initialLoad.value))

        let failedRefresh = await readNextPageLoadedEvent(from: viewModel)
        await viewModel.refresh()
        _ = try #require(await failedRefresh.value)

        let retriedRefresh = await readNextPageLoadedEvent(from: viewModel)

        // ACT
        viewModel.interactWithError(shouldRetry: true)

        let entries = try requireSuccessEntries(try #require(await retriedRefresh.value))

        // ASSERT
        #expect(entries == refreshedPage.entries)
        #expect(viewModel.items == [10, 11])
        #expect(viewModel.latestResult == refreshedPage)
        #expect(viewModel.hasMore)
        #expect(viewModel.loadState == .loaded)
        #expect(await stub.requestedPages() == [nil, nil, nil])
    }

    @Test func reset_keepsIdleStateWhenCancelledLoadEventuallyCompletes() async {
        // ARRANGE
        let stub = FetchStub(responses: [.suspended])
        let viewModel = makeViewModel(with: stub)

        // ACT
        viewModel.loadFirstPageIfNeeded()
        await busyWaitAsync {
            let pendingRequestCount = await stub.pendingRequestCount()
            return pendingRequestCount == 1
        }
        viewModel.reset()
        await stub.resumeNextRequest(
            with: .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2)))
        )
        await busyWaitAsync {
            let completedRequestCount = await stub.completedRequestCount()
            return completedRequestCount == 1
        }

        // ASSERT
        #expect(viewModel.items.isEmpty)
        #expect(!viewModel.hasMore)
        #expect(viewModel.latestResult == nil)
        #expect(viewModel.loadState == .idle)
    }

    private func makeViewModel(
        with stub: FetchStub
    ) -> PaginatedListViewModelImpl<Int, NullPaginationParams> {
        PaginatedListViewModelImpl { page in
            try await stub.fetch(page)
        }
    }

    private func readNextPageLoadedEvent(
        from viewModel: PaginatedListViewModelImpl<Int, NullPaginationParams>
    ) async -> Task<Result<[Int], Error>?, Never> {
        let (_, stream) = await viewModel.pageLoadedEvent.stream()
        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }
        await busyWaitAsync {
            let observerCount = await viewModel.pageLoadedEvent.observerCount
            return observerCount > 0
        }

        return reader
    }

    private func readPageLoadedEvents(
        from viewModel: PaginatedListViewModelImpl<Int, NullPaginationParams>,
        count: Int
    ) async -> Task<[Result<[Int], Error>], Never> {
        let (_, stream) = await viewModel.pageLoadedEvent.stream()
        let reader = Task {
            var iterator = stream.makeAsyncIterator()
            var values: [Result<[Int], Error>] = []

            for _ in 0..<count {
                if let value = await iterator.next() {
                    values.append(value)
                }
            }

            return values
        }
        await busyWaitAsync {
            let observerCount = await viewModel.pageLoadedEvent.observerCount
            return observerCount > 0
        }

        return reader
    }

    private func requireSuccessEntries(_ result: Result<[Int], Error>) throws -> [Int] {
        switch result {
        case .success(let entries):
            return entries
        case .failure(let error):
            throw error
        }
    }
}

private actor FetchStub {
    typealias Page = Pagination<NullPaginationParams>.Page<Int>
    
    enum Response {
        case immediate(Result<Page, Error>)
        case suspended
    }

    private var responses: [Response]
    private var recordedPages: [Pagination<NullPaginationParams>?] = []
    private var pendingContinuations: [CheckedContinuation<Result<Page, Error>, Never>] = []
    private var completedFetchCount = 0

    init(_ results: [Result<Page, Error>]) {
        self.responses = results.map(Response.immediate)
    }
    
    init(responses: [Response]) {
        self.responses = responses
    }

    func fetch(_ page: Pagination<NullPaginationParams>?) async throws -> Page {
        recordedPages.append(page)

        guard !responses.isEmpty else {
            throw InvalidDataError()
        }

        let result = switch responses.removeFirst() {
        case .immediate(let result):
            result
        case .suspended:
            await withCheckedContinuation { continuation in
                pendingContinuations.append(continuation)
            }
        }
        completedFetchCount += 1

        return try result.get()
    }

    func requestedPages() -> [Pagination<NullPaginationParams>?] {
        recordedPages
    }
    
    func pendingRequestCount() -> Int {
        pendingContinuations.count
    }
    
    func resumeNextRequest(with result: Result<Page, Error>) {
        guard !pendingContinuations.isEmpty else { return }
        pendingContinuations.removeFirst().resume(returning: result)
    }
    
    func completedRequestCount() -> Int {
        completedFetchCount
    }
}
