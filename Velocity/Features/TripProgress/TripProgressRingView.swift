//
//  TripProgressRingView.swift
//  Velocity
//

import SwiftUI

struct TripProgressRingView: View {
    let progressFraction: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth: CGFloat = 14
            let radius = (size / 2) - lineWidth / 2
            let progress = CGFloat(Self.clamp01(progressFraction))

            ZStack {
                Circle()
                    .stroke(VelocityColor.primary.opacity(0.18), style: StrokeStyle(lineWidth: lineWidth))

                Circle()
                    .trim(from: 0, to: CGFloat(Self.clamp01(progressFraction)))
                    .stroke(
                        VelocityColor.primary,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: progressFraction)

                // Knob rotates around the ring.
                Circle()
                    .fill(VelocityColor.primary)
                    .frame(width: 18, height: 18)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(progress * 360))
                    .shadow(color: VelocityColor.primary.opacity(0.35), radius: 8, x: 0, y: 4)
            }
        }
    }

    private static func clamp01(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

