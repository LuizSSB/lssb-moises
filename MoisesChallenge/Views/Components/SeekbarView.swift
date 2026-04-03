//
//  SeekbarView.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import SwiftUI

struct SeekbarView: View {
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
