//
//  Extensions.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

struct ViewModelConstants {
    private init() {}
    
    static let defaultSizePage = 10
}

extension IoCContainer {
    func songSearchPaginatedListViewModel(
        params: SongSearchParams,
        initialEntries: [Song],
        limit: Int = ViewModelConstants.defaultSizePage
    ) -> any PaginatedListViewModel<Song> {
        let service = songSearchService()
        return paginatedListViewModel(
            ofKind: .dynamic(
                {
                    try await service.search($0 ?? .first(params: params, limit: limit))
                },
                initialPage: .init(
                    entries: initialEntries,
                    pagination: .first(params: params, limit: initialEntries.count)
                )
            )
        )
    }
    
    func recentSongsPaginatedListViewModel(
        limit: Int = ViewModelConstants.defaultSizePage
    ) -> any PaginatedListViewModel<Song> {
        let service = interactionService()
        return paginatedListViewModel(ofKind: .dynamic {
            let page = try await service.listPlayedSongs($0 ?? .first(limit: limit))
            return .init(
                entries: page.entries.map(\.song),
                pagination: page.pagination
            )
        })
    }
}
