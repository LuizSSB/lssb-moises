//
//  SongRowView.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 31/03/26.
//
import SwiftUI

struct SongRowView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(artworkURL: song.itemArtworkURL)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.displayTitle)
                    .font(.body)
                    .lineLimit(1)
                Text(song.displayArtistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
