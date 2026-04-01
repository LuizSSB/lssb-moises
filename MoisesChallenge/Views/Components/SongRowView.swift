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
            artworkView
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title ?? "Unknown title")
                    .font(.body)
                    .lineLimit(1)
                Text(song.artist ?? "Unknown artist")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var artworkView: some View {
        if let url = song.itemArtworkURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                artworkPlaceholder
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            artworkPlaceholder
        }
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
            }
    }
}
