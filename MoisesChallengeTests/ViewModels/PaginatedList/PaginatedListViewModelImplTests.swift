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
        let viewModel = makeViewModel(with: FetchStub([]))

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.loadState == .idle)
        #expect(viewModel.latestResult == nil)
    }

    @Test func loadFirstPageIfNeeded_loadsFirstPageAndStoresFetchedEntries() async throws {
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)
        let result = await readNextPageLoadedEvent(from: viewModel)

        viewModel.loadFirstPageIfNeeded()

        let page = try requireSuccess(try #require(await result.value))

        #expect(page.entries == [1, 2])
        #expect(viewModel.items == [1, 2])
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.latestResult == page)
        #expect(await stub.requestedPages() == [nil])
    }

    @Test func loadFirstPageIfNeeded_setsEmptyWhenFetchedPageHasNoEntries() async throws {
        let stub = FetchStub([
            .success(Page(entries: [], pagination: .init(offset: 0, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)
        let result = await readNextPageLoadedEvent(from: viewModel)

        viewModel.loadFirstPageIfNeeded()

        _ = try requireSuccess(try #require(await result.value))

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.loadState == .empty)
        #expect(viewModel.latestResult == Page(entries: [], pagination: .init(offset: 0, limit: 2)))
    }

    @Test func loadNextPage_appendsEntriesFromFollowingPage() async throws {
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))),
            .success(Page(entries: [3], pagination: .init(offset: 2, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)

        let firstLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccess(try #require(await firstLoad.value))

        let nextLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadNextPage()
        let page = try requireSuccess(try #require(await nextLoad.value))

        #expect(page.entries == [3])
        #expect(viewModel.items == [1, 2, 3])
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.latestResult == page)
        #expect(
            await stub.requestedPages() == [
                nil,
                Pagination(offset: 2, limit: 2)
            ]
        )
    }

    @Test func refresh_replacesItemsAndLoadsNextPageWhenListAlreadyHadEntries() async throws {
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))),
            .success(Page(entries: [10, 11], pagination: .init(offset: 0, limit: 2))),
            .success(Page(entries: [12], pagination: .init(offset: 2, limit: 2)))
        ])
        let viewModel = makeViewModel(with: stub)

        let initialLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccess(try #require(await initialLoad.value))

        let refreshEvents = await readPageLoadedEvents(from: viewModel, count: 2)
        await viewModel.refresh()
        let events = await refreshEvents.value

        #expect(events.count == 2)
        #expect(try requireSuccess(events[0]).entries == [10, 11])
        #expect(try requireSuccess(events[1]).entries == [12])
        #expect(viewModel.items == [10, 11, 12])
        #expect(viewModel.loadState == .loaded)
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
        let stub = FetchStub([
            .failure(InvalidDataError())
        ])
        let viewModel = makeViewModel(with: stub)
        let result = await readNextPageLoadedEvent(from: viewModel)

        viewModel.loadFirstPageIfNeeded()

        let failure = try #require(await result.value)

        switch failure {
        case .success:
            Issue.record("Expected the first page load to fail.")
        case .failure(let error):
            #expect(error is InvalidDataError)
        }

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.latestResult == nil)
        #expect(viewModel.loadState == .error(InvalidDataError().userFacingError))
    }

    @Test func interactWithError_retriesFailedFirstPageLoadWhenRequested() async throws {
        let stub = FetchStub([
            .failure(InvalidDataError()),
            .success(Page(entries: [1], pagination: .init(offset: 0, limit: 1)))
        ])
        let viewModel = makeViewModel(with: stub)

        let failedLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try #require(await failedLoad.value)

        let retriedLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.interactWithError(shouldRetry: true)
        let page = try requireSuccess(try #require(await retriedLoad.value))

        #expect(page.entries == [1])
        #expect(viewModel.items == [1])
        #expect(viewModel.loadState == .loaded)
        #expect(await stub.requestedPages() == [nil, nil])
    }

    @Test func interactWithError_restoresIdleStateWhenAbandoningFailedFirstPageLoad() async throws {
        let stub = FetchStub([
            .failure(InvalidDataError())
        ])
        let viewModel = makeViewModel(with: stub)
        let result = await readNextPageLoadedEvent(from: viewModel)

        viewModel.loadFirstPageIfNeeded()
        _ = try #require(await result.value)

        viewModel.interactWithError(shouldRetry: false)

        #expect(viewModel.loadState == .idle)
        #expect(viewModel.items.isEmpty)
    }

    @Test func interactWithError_restoresLoadedStateWhenAbandoningFailedNextPageLoad() async throws {
        let stub = FetchStub([
            .success(Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2))),
            .failure(InvalidDataError())
        ])
        let viewModel = makeViewModel(with: stub)

        let initialLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadFirstPageIfNeeded()
        _ = try requireSuccess(try #require(await initialLoad.value))

        let nextLoad = await readNextPageLoadedEvent(from: viewModel)
        viewModel.loadNextPage()
        _ = try #require(await nextLoad.value)

        viewModel.interactWithError(shouldRetry: false)

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.items == [1, 2])
        #expect(viewModel.latestResult == Page(entries: [1, 2], pagination: .init(offset: 0, limit: 2)))
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
    ) async -> Task<Result<Page, Error>?, Never> {
        let (_, stream) = await viewModel.pageLoadedEvent.stream()

        return Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }
    }

    private func readPageLoadedEvents(
        from viewModel: PaginatedListViewModelImpl<Int, NullPaginationParams>,
        count: Int
    ) async -> Task<[Result<Page, Error>], Never> {
        let (_, stream) = await viewModel.pageLoadedEvent.stream()

        return Task {
            var iterator = stream.makeAsyncIterator()
            var values: [Result<Page, Error>] = []

            for _ in 0..<count {
                if let value = await iterator.next() {
                    values.append(value)
                }
            }

            return values
        }
    }

    private func requireSuccess(_ result: Result<Page, Error>) throws -> Page {
        switch result {
        case .success(let page):
            return page
        case .failure(let error):
            throw error
        }
    }
}

private actor FetchStub {
    typealias Page = Pagination<NullPaginationParams>.Page<Int>

    private var results: [Result<Page, Error>]
    private var recordedPages: [Pagination<NullPaginationParams>?] = []

    init(_ results: [Result<Page, Error>]) {
        self.results = results
    }

    func fetch(_ page: Pagination<NullPaginationParams>?) async throws -> Page {
        recordedPages.append(page)

        guard !results.isEmpty else {
            throw InvalidDataError()
        }

        return try results.removeFirst().get()
    }

    func requestedPages() -> [Pagination<NullPaginationParams>?] {
        recordedPages
    }
}
