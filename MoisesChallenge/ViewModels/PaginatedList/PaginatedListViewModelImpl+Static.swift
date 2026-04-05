//
//  PaginatedListViewModelImpl+Static.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 05/04/26.
//

extension PaginatedListViewModelImpl {
    convenience init(staticItems: [Item]) where PaginationParams == NullPaginationParams {
        self.init { page in
            guard let page else {
                return .init(entries: staticItems, pagination: .first())
            }
            
            if page.offset >= staticItems.endIndex - 1 {
                return .init(entries: [], pagination: page)
            }
            
            let limit = page.limit ?? Int.max
            
            return .init(
                entries: Array(staticItems[page.offset..<min(page.offset + limit, staticItems.count)]),
                pagination: .init(
                    offset: page.offset,
                    limit: limit
                )
            )
        }
    }
}
