//
//  ArtworkView.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI
import Kingfisher

struct ArtworkView<PlaceholderContent: View>: View {
    let artworkURL: URL?
    @ViewBuilder let placeholderContent: (Progress?) -> PlaceholderContent
    
    var body: some View {
        if let url = artworkURL {
            KFImage.url(url)
                .placeholder(placeholderContent)
                .resizable()
                .scaledToFit()
        } else {
            placeholderContent(nil)
        }
    }
}

struct ArtworkViewDefaultPlaceholderContent: View {
    var body: some View {
        GeometryReader { reader in
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: reader.size.width * 0.25))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .accessibilityHidden(true)
        }
    }
}

extension ArtworkView where PlaceholderContent == ArtworkViewDefaultPlaceholderContent {
    init(artworkURL: URL?) {
        self.init(artworkURL: artworkURL) { _ in
            ArtworkViewDefaultPlaceholderContent()
        }
    }
}
