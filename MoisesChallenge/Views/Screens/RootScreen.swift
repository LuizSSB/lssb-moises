//
//  SongListScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//

import SwiftUI

struct SongListScreen: View {
    @State var viewModel: RootViewModel
    
    var body: some View {
        SearchBarContentContainer {
            if let search = viewModel.search {
                SongListView(viewModel: search)
            } else {
                Text("foo")
            }
        } onSearchStatusChanged: { enabled in
            viewModel.setSearchEnabled(enabled)
        }
        .navigationTitle("Songs")
        .searchable(
            text: .init(
                get: { viewModel.state.searchTerm ?? "" },
                set: { viewModel.setSearchTerm(term: $0) }
            ),
            placement: .navigationBarDrawer
        )
        .onSubmit(of: .search) {
            viewModel.confirmSearchTerm()
        }
        .listStyle(.plain)
    }
}
