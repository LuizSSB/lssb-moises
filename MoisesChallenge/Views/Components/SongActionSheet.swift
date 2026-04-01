//
//  SongActionSheet.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import SwiftUI

// MARK: - Actions

enum SongAction: CaseIterable, Identifiable {
    case viewAlbum
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .viewAlbum: return "View album"
        }
    }
    
    var icon: String {
        switch self {
        case .viewAlbum: return "square.stack"
        }
    }
    
    var isDestructive: Bool { false }
}

// MARK: - View modifier

private struct SongActionSheetModifier: ViewModifier {
    @Binding var song: Song?
    let onAction: (SongAction) -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: .init(
                    get: { song != nil },
                    set: { _ in song = nil }
                )
            ) {
                if let song {
                    SongActionSheetContent(song: song) { action in
                        self.song = nil
                        onAction(action)
                    }
                    // Snap to a compact height — just tall enough for the header + rows
                    .presentationDetents([.height(SongActionSheetContent.preferredHeight)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(nil)
                }
            }
    }
}

// MARK: - Sheet content

private struct SongActionSheetContent: View {
    private static let headerHeight: CGFloat = 72
    private static let rowHeight: CGFloat = 56
    private static let bottomPadding: CGFloat = 16
    
    static var preferredHeight: CGFloat {
        headerHeight + CGFloat(SongAction.allCases.count) * rowHeight + bottomPadding
    }
    
    let song: Song
    let onAction: (SongAction) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            actionsView
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 2) {
            Text(song.displayTitle)
                .font(.headline)
                .lineLimit(1)
            Text(song.displayArtist)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.headerHeight)
        .padding(.horizontal)
    }
    
    private var actionsView: some View {
        ForEach(SongAction.allCases) { action in
            Button {
                onAction(action)
            } label: {
                HStack {
                    Image(systemName: action.icon)
                        .frame(width: 24)
                        .foregroundStyle(action.isDestructive ? .red : .primary)
                    Text(action.label)
                        .foregroundStyle(action.isDestructive ? .red : .primary)
                    Spacer()
                }
                .frame(height: Self.rowHeight)
                .padding(.horizontal, 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if action != SongAction.allCases.last {
                Divider()
            }
        }
    }
}

// MARK: - View extension

extension View {
    func songActionSheet(for song: Binding<Song?>, onAction: @escaping (SongAction) -> Void) -> some View {
        modifier(SongActionSheetModifier(song: song, onAction: onAction))
    }
}
