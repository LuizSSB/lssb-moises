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
    
    private let trackHeight: CGFloat = 8
    private let thumbSize: CGFloat = 24
    private let touchHeight: CGFloat = 36
    
    private var displayProgress: Double {
        isDragging ? dragProgress : progress
    }
    
    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let thumbRadius = thumbSize / 2
            let trackWidth = max(width - thumbSize, 1)
            let clampedProgress = displayProgress.clamped(to: 0...1)
            let thumbCenterX = thumbRadius + (trackWidth * clampedProgress)
            
            ZStack(alignment: .leading) {
                // Complete bar
                Capsule()
                    .fill(Color.seekbar.opacity(0.25))
                    .frame(width: trackWidth, height: trackHeight)
                    .padding(.horizontal, thumbRadius)
                    .frame(height: trackHeight)

                // Filled bar
                Capsule()
                    .fill(Color.seekbar.opacity(0.6))
                    .frame(width: trackWidth * clampedProgress, height: trackHeight)
                    .padding(.horizontal, thumbRadius)
                    .frame(height: trackHeight, alignment: .leading)
                
                // Thumb
                Circle()
                    .fill(Color.seekbarThumb)
                    .frame(width: thumbSize, height: thumbSize)
                    .position(x: thumbCenterX, y: touchHeight / 2)
            }
            .frame(height: touchHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        dragProgress = ((value.location.x - thumbRadius) / trackWidth)
                            .clamped(to: 0...1)
                    }
                    .onEnded { value in
                        let fraction = ((value.location.x - thumbRadius) / trackWidth)
                            .clamped(to: 0...1)
                        onSeek(fraction)
                        isDragging = false
                    }
            )
            .animation(.easeOut(duration: 0.12), value: clampedProgress)
            .accessibilityElement()
            .accessibilityLabel(String(localized: .playerSeekbarAccessibilityLabel))
            .accessibilityValue(Text(String(localized: .playerSeekbarAccessibilityValue(Int(clampedProgress * 100)))))
            .accessibilityAdjustableAction { direction in
                let step = 0.05
                switch direction {
                case .increment:
                    onSeek((displayProgress + step).clamped(to: 0...1))
                case .decrement:
                    onSeek((displayProgress - step).clamped(to: 0...1))
                @unknown default:
                    break
                }
            }
        }
        .frame(height: touchHeight)
    }
}
