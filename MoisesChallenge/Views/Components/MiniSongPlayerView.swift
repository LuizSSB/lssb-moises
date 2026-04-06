//
//  MiniSongPlayerView.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 06/04/26.
//

import SwiftUI

struct MiniSongPlayerView: View {
    let viewModel: any FocusedSongPlayerViewModel
    let openPlayer: () -> Void

    var body: some View {
        if let song = viewModel.currentSong {
            HStack {
                Button(action: openPlayer) {
                    SongRowView(song: song)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    String(localized: viewModel.playbackState == .playing ? .playerPauseAccessibilityLabel : .playerPlayAccessibilityLabel)
                )
            }
            .padding(.horizontal)
            .padding(.vertical)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal)
            .padding(.bottom, 8)
            .shadow(color: .shadowHighlight.opacity(0.08), radius: 12, y: 2)
        }
    }
}
