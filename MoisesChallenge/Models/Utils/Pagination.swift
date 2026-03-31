//
//  Pagination.swift
//  SFR3
//
//  Created by Luiz SSB on 19/04/25.
//

struct Pagination<TParams: Equatable & Hashable>: Equatable, Hashable {
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
    
    struct Page<TEntry: Equatable & Hashable>: Equatable, Hashable {
        let entries: [TEntry]
        let pagination: Pagination
        
        var reachedEnd: Bool {
            if let limit = pagination.limit {
                return limit > entries.count
            }
            return false
        }
    }
}
