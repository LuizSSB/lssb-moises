//
//  PlaybackQueueDependencyKind.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

enum PlaybackQueueDependencyKind<Item: Equatable & Hashable & Sendable, PaginationParams: Hashable & Sendable> {
    case `static`([Item])
    case paginated(any PaginatedListViewModel<Item, PaginationParams>)
}

extension PlaybackQueueDependencyKind where PaginationParams == NullPaginationParams {
    init(staticItems: [Item]) {
        self = .static(staticItems)
    }
}
