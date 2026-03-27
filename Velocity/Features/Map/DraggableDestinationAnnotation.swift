//
//  DraggableDestinationAnnotation.swift
//  Velocity
//
//  Converts global drag points through MapProxy so the pin tracks the finger.
//  Reverse geocoding and routing run only after `endDraggingDestination` in
//  the view model — not on every drag tick.
//

import MapKit
import SwiftUI

struct DraggableDestinationAnnotation: View {
    let proxy: MapProxy
    @Bindable var viewModel: MapViewModel
    let symbolName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(VelocityColor.surfaceContainerHighest.opacity(0.96))
                .frame(width: 28, height: 28)
            Circle()
                .stroke(VelocityColor.primary, lineWidth: 2)
                .frame(width: 28, height: 28)
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VelocityColor.primary)
        }
            .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
            .accessibilityLabel("Destination")
            .accessibilityHint("Drag to move your destination")
            .highPriorityGesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .global)
                    .onChanged { value in
                        if viewModel.mapMode != .selectingDestination {
                            viewModel.beginDraggingDestination()
                        }
                        if let coord = proxy.convert(value.location, from: .global) {
                            viewModel.updateDraggedDestination(coord)
                        }
                    }
                    .onEnded { _ in
                        viewModel.endDraggingDestination()
                    }
            )
    }
}
