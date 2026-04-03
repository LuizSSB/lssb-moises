//
//  SongPlayerScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

struct SongPlayerScreen: View {
    @State var viewModel: SongPlayerViewModel
    var showsOptions = true
    
    @State private var actionSheetSong: Song?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            
            ArtworkView(artworkURL: viewModel.currentSong?.mainArtworkURL)
                .frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 12, y: 6)
            
            Spacer(minLength: 24)
            
            infoSection
                .padding(.horizontal, 32)
            
            Spacer(minLength: 16)
            
            seekbarSection
                .padding(.horizontal, 32)
            
            Spacer(minLength: 24)
            
            controlsSection
                .padding(.horizontal, 32)
            
            Spacer(minLength: 40)
        }
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
    
    // MARK: - Song info
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.currentSong?.displayTitle ?? "—")
                .font(.title2.bold())
                .lineLimit(1)
            Text(viewModel.currentSong?.displayArtistName ?? "—")
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Seekbar
    
    private var seekbarSection: some View {
        VStack(spacing: 4) {
            SeekbarView(progress: viewModel.progress) { fraction in
                viewModel.seek(to: fraction)
            }
            
            HStack {
                Text(viewModel.elapsed.formattedDuration)
                Spacer()
                Text(viewModel.duration.map { $0.formattedDuration } ?? "--:--")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Controls
    
    private func moveButton(direction: SongQueuePlaybackDirection) -> some View {
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
        .disabled(!viewModel.has(direction) || viewModel.isLoading(direction))
    }
    
    private var controlsSection: some View {
        HStack(spacing: 48) {
            moveButton(direction: .previous)
            
            Button {
                viewModel.togglePlayPause()
            } label: {
                playPauseLabel
                    .font(.system(size: 48))
                    .frame(width: 64, height: 64)
            }
            .disabled(viewModel.playbackState == .loading)
            
            moveButton(direction: .next)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - SeekbarView

private struct SeekbarView: View {
    
    let progress: Double
    let onSeek: (Double) -> Void
    
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    private var displayProgress: Double {
        isDragging ? dragProgress : progress
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                
                Capsule()
                    .fill(Color.primary)
                    .frame(width: max(0, geo.size.width * displayProgress), height: 4)
                
                // Invisible wide drag target
                Color.clear
                    .contentShape(Rectangle())
                    .frame(height: 32)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                dragProgress = (value.location.x / geo.size.width)
                                    .clamped(to: 0...1)
                            }
                            .onEnded { value in
                                let fraction = (value.location.x / geo.size.width)
                                    .clamped(to: 0...1)
                                onSeek(fraction)
                                isDragging = false
                            }
                    )
            }
            .frame(height: 32)
            .alignmentGuide(.top) { _ in 0 }
        }
        .frame(height: 32)
    }
}

