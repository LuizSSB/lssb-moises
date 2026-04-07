//
//  FocusedSongPlayerScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

struct FocusedSongPlayerView: View {
    let viewModel: any FocusedSongPlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            artworkSection
            
            infoSection
                .padding(.bottom)
            
            seekbarSection
                .padding(.bottom)
            
            controlsSection
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    private var artworkSection: some View {
        ZStack {
            ArtworkView(artworkURL: viewModel.currentSong?.mainArtworkURL)
                .frame(maxWidth: 264, maxHeight: 264)
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .accessibilityHidden(true)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.currentSong?.displayTitle ?? "—")
                .font(.title.bold())
                .lineLimit(1)
            
            HStack {
                Text(viewModel.currentSong?.displayArtistName ?? "—")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    viewModel.toggleRepeatMode()
                } label: {
                    Image(systemName: {
                        switch viewModel.repeatMode {
                        case .none, .all: return "repeat"
                        case .current: return "repeat.1"
                        }
                    }())
                    .font(.body)
                    .foregroundStyle(viewModel.repeatMode == .none ? .secondary : .primary)
                    .frame(width: 24, height: 24)
                }
                .buttonStyle(.adaptivePlain)
                .accessibilityLabel(String(localized: .playerRepeatAccessibilityLabel))
                .accessibilityValue(repeatModeAccessibilityValue)
            }
            
            if let playbackErrorMessage {
                Text(playbackErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.danger)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var seekbarSection: some View {
        VStack(spacing: 2) {
            SeekbarView(progress: viewModel.progress) { fraction in
                viewModel.seek(to: fraction)
            }
            
            HStack {
                Text(viewModel.elapsed.formattedDuration)
                    .accessibilityLabel(String(localized: .playerElapsedTimeAccessibilityLabel(viewModel.elapsed.formattedDuration)))
                Spacer()
                Text(remainingDurationText)
                    .accessibilityLabel(String(localized: .playerRemainingTimeAccessibilityLabel(remainingDurationText)))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary.opacity(0.9))
        }
    }
    
    private var remainingDurationText: String {
        guard let duration = viewModel.duration else { return "--:--" }
        let remaining = max(duration - viewModel.elapsed, 0)
        return "-\(remaining.formattedDuration)"
    }
    
    // MARK: - Controls
    
    private func moveButton(direction: PlaybackQueueDirection) -> some View {
        Button {
            viewModel.move(to: direction)
        } label: {
            if viewModel.isLoading(direction) {
                ProgressView()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: {
                    switch direction {
                    case .previous: return "backward.fill"
                    case .next: return "forward.fill"
                    }
                }())
                .font(.system(size: 28))
            }
        }
        .buttonStyle(.adaptivePlain)
        .disabled(viewModel.isLoading(direction))
        .accessibilityLabel(
            String(
                localized: direction == .previous ? .playerPreviousAccessibilityLabel : .playerNextAccessibilityLabel
            )
        )
    }
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 28) {
                moveButton(direction: .previous)
                
                Button {
                    viewModel.togglePlayPause()
                } label: {
                    playPauseLabel
                        .font(.system(size: 38))
                        .frame(width: 72, height: 72)
                        .contentShape(Circle())
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .buttonStyle(.plain) // .glass and .glassProminent are not totally round
                .disabled(viewModel.playbackState == .loading)
                .accessibilityLabel(playPauseAccessibilityLabel)
                
                moveButton(direction: .next)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private var playPauseLabel: some View {
        switch viewModel.playbackState {
        case .loading:
            ProgressView()
        case .playing:
            Image(systemName: "pause.fill")
        default:
            Image(systemName: "play.fill")
        }
    }

    private var repeatModeAccessibilityValue: String {
        String(localized: {
            switch viewModel.repeatMode {
            case .none: return .playerRepeatAccessibilityValueOff
            case .all: return .playerRepeatAccessibilityValueAll
            case .current: return .playerRepeatAccessibilityValueCurrent
            }
        }())
    }

    private var playPauseAccessibilityLabel: String {
        String(localized: {
            switch viewModel.playbackState {
            case .playing: return .playerPauseAccessibilityLabel
            default: return .playerPlayAccessibilityLabel
            }
        }())
    }

    private var playbackErrorMessage: String? {
        guard case let .error(message) = viewModel.playbackState else { return nil }
        return message
    }
}


