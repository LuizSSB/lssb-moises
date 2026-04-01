//
//  RootViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI
import FactoryKit

private let defaultSearchLimit = 10

@Observable class RootViewModel: ViewModel {
    struct State: ViewModelState {
        var searchTerm: String?
    }
    
    private(set) var state = State()
    
    private(set) var search: SongListViewModel?
    
    func setSearchEnabled(_ enabled: Bool) {
        if enabled {
            search = Container.shared.songListViewModel()
        } else {
            search = nil
        }
    }
    
    func setSearchTerm(term: String) {
        state.searchTerm = term
    }
    
    func confirmSearchTerm() {
        search?.listSongs(with: state.searchTerm)
    }
}

extension Container {
    var rootViewModel: Factory<RootViewModel> {
        self { @MainActor in RootViewModel() }
    }
}
