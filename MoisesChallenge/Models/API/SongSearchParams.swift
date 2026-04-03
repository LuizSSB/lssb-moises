//
//  SongSearch.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//


struct SongSearchParams: Equatable, Hashable {
    let searchTerm: String
    
    var allResults: [Song]? // HACK: see note at SongSearchService.iTunes
}

typealias SongSearchPagination = Pagination<SongSearchParams>
typealias SongSearchPage = SongSearchPagination.Page<Song>
