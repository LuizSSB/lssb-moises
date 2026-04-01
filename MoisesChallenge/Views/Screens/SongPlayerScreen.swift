//
//  SongPlayerScreen.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

struct SongPlayerScreen: View {
    
    @State var viewModel: SongPlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            
            artworkSection
            
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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    // MARK: - Artwork
    
    private var artworkSection: some View {
        Group {
            if let url = viewModel.currentSong?.mainArtworkURL {
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
        .padding(.horizontal, 32)
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
    
    // MARK: - Song info
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.currentSong?.title ?? "—")
                .font(.title2.bold())
                .lineLimit(1)
            Text(viewModel.currentSong?.artist ?? "—")
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
    
    private var controlsSection: some View {
        HStack(spacing: 48) {
            Button {
                viewModel.previousSong()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
            }
            .disabled(!viewModel.hasPrevious)
            
            Button {
                viewModel.togglePlayPause()
            } label: {
                playPauseLabel
                    .font(.system(size: 48))
                    .frame(width: 64, height: 64)
            }
            .disabled(viewModel.playbackState == .loading)
            
            Button {
                viewModel.nextSong()
            } label: {
                if viewModel.isLoadingNext {
                    ProgressView()
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 28))
                }
            }
            .disabled(!viewModel.hasNext && !viewModel.isLoadingNext)
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

