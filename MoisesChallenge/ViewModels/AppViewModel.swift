//
//  AppViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 18/04/25.
//

import FactoryKit

class AppViewModel: ViewModel {
    struct State: ViewModelState {
    }
    
    var state = State()
}

extension Container {
    var appViewModel: Factory<AppViewModel> {
        self { AppViewModel() }
            .singleton
    }
}
