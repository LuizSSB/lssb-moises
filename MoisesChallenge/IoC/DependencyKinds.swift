//
//  DependencyKinds.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

enum PlaybackQueueDependencyKind<Item: Equatable & Hashable & Sendable> {
    case `static`([Item])
    case paginated(any PaginatedListViewModel<Item>)
}

extension PlaybackQueueDependencyKind {
    init(staticItems: [Item]) {
        self = .static(staticItems)
    }
}

enum PaginatedListViewModelDependencyKind<Item: Hashable & Sendable, PaginationParams: Hashable & Sendable> {
    case `static`([Item])
    case dynamic(
        @Sendable (_ page: Pagination<PaginationParams>?) async throws -> Pagination<PaginationParams>.Page<Item>,
        initialPage: Pagination<PaginationParams>.Page<Item>? = nil
    )
}

extension PaginatedListViewModelDependencyKind where PaginationParams == NullPaginationParams {
    init(staticItems: [Item]) {
        self = .static(staticItems)
    }
}
