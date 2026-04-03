//
//  SongPlayerScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

struct SongPlayerScreen: View {
    @State var viewModel: any SongPlayerViewModel
    var showsOptions = true
    
    @State private var actionSheetSong: Song?
    
    var body: some View {
        VStack(spacing: 0) {
            artworkSection
            
            infoSection
                .padding(.bottom)
            
            seekbarSection
                .padding(.bottom)
            
            controlsSection
        }
        .frame(maxHeight: .infinity)
        .padding(24)
        .navigationTitle(viewModel.currentSong?.displayAlbumTitle ?? "-")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if showsOptions,
                   let currentSong = viewModel.currentSong{
                    Button {
                        actionSheetSong = currentSong
                    } label: {
                        Image(systemName: "ellipsis")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .songActionSheet(for: $actionSheetSong) { song, action in
            switch action {
            case .viewAlbum:
                viewModel.onSelectAlbum(of: song)
            }
        }
        .navigationDestination(presentationViewModel: viewModel.album) {
            AlbumScreen(viewModel: $0)
        }
    }
    
    private var artworkSection: some View {
        ZStack {
            ArtworkView(artworkURL: viewModel.currentSong?.mainArtworkURL)
                .frame(maxWidth: 264, maxHeight: 264)
                .clipShape(RoundedRectangle(cornerRadius: 32))
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
                    viewModel.onToggleRepeatMode()
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var seekbarSection: some View {
        VStack(spacing: 2) {
            SeekbarView(progress: viewModel.progress) { fraction in
                viewModel.onSeek(to: fraction)
            }
            
            HStack {
                Text(viewModel.elapsed.formattedDuration)
                Spacer()
                Text(remainingDurationText)
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
            viewModel.onMove(to: direction)
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
        .disabled(!viewModel.has(direction) || viewModel.isLoading(direction))
    }
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 28) {
                moveButton(direction: .previous)
                
                Button {
                    viewModel.onTogglePlayPause()
                } label: {
                    playPauseLabel
                        .font(.system(size: 38))
                        .frame(width: 72, height: 72)
                        .contentShape(Circle())
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .buttonStyle(.plain) // .glass and .glassProminent are not totally round
                .disabled(viewModel.playbackState == .loading)
                
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
}
