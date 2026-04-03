//
//  Pagination.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 19/04/25.
//

struct Pagination<TParams: Equatable & Hashable & Sendable>: Equatable, Hashable {
    var params: TParams
    var offset: Int
    var limit: Int?
    
    var lastIndex: Int? {
        if let limit {
            return offset + limit
        }
        return nil
    }
    
    var next: Self {
        return .init(
            params: params,
            offset: offset + (limit ?? 0),
            limit: limit
        )
    }
    
    static func first(params: TParams, limit: Int? = nil) -> Self {
        return .init(params: params, offset: 0, limit: limit)
    }
    
    struct Page<TEntry: Equatable & Hashable & Sendable>: Equatable, Hashable {
        let entries: [TEntry]
        let pagination: Pagination
        
        var hasMore: Bool {
            if let limit = pagination.limit {
                return limit == entries.count
            }
            return false
        }
    }
}

struct NullPaginationParams: Hashable, Sendable {
    static let instance = Self()
}

extension Pagination where TParams == NullPaginationParams {
    init(offset: Int, limit: Int? = nil) {
        self.init(params: .instance, offset: offset, limit: limit)
    }
    
    static func first(limit: Int? = nil) -> Self {
        return .init(params: .instance, offset: 0, limit: limit)
    }
}

enum PaginatedListLoadState: Equatable {
    case idle
    case loadingFirstPage
    case loadingNextPage
    case refreshing
    case loaded
    case empty
    case error(UserFacingError)
}
