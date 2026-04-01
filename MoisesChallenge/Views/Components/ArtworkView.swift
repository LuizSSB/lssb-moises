//
//  ArtworkView.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

struct ArtworkView: View {
    let artworkURL: URL?
    
    var body: some View {
        Group {
            if let url = artworkURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    artworkPlaceholder
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 12, y: 6)
    }
    
    
    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 72))
                    .foregroundStyle(.secondary)
            }
    }
}
