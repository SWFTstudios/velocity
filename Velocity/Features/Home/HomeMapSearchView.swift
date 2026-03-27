//
//  HomeMapSearchView.swift
//  Velocity
//

import SwiftUI

struct HomeMapSearchView: View {
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore
    @Bindable var mapViewModel: MapViewModel
    var onSearchTapped: () -> Void
    var onOpenSounds: () -> Void
    var onOpenSettings: () -> Void
    var onOpenTripSetup: () -> Void
    var showTripProgressReshowCTA: Bool
    var onTripProgressReshowTapped: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            MapScreen(
                viewModel: mapViewModel,
                tripStore: tripStore,
                settingsStore: settingsStore,
                onSearchTapped: onSearchTapped,
                onOpenSounds: onOpenSounds,
                onOpenSettings: onOpenSettings,
                onOpenTripSetup: onOpenTripSetup
            )
            .background(VelocityColor.surface)

            if showTripProgressReshowCTA {
                Button {
                    onTripProgressReshowTapped()
                } label: {
                    HStack(spacing: VelocitySpacing.sm) {
                        Image(systemName: "timer.circle.fill")
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                        Text("Trip progress")
                            .font(VelocityFontStyle.body(14))
                            .foregroundStyle(VelocityColor.onSurface)
                    }
                    .padding(.horizontal, VelocitySpacing.md)
                    .padding(.vertical, 10)
                    .background(VelocityColor.surfaceContainerHighest.opacity(0.92))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 120)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        let store = TripSessionStore()
        HomeMapSearchView(
            tripStore: store,
            settingsStore: UserSettingsStore(),
            mapViewModel: MapViewModel(tripStore: store, services: .preview),
            onSearchTapped: {},
            onOpenSounds: {},
            onOpenSettings: {},
                onOpenTripSetup: {},
                showTripProgressReshowCTA: false,
                onTripProgressReshowTapped: {}
        )
    }
}
