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
    var showTripSetupReshowCTA: Bool
    var onTripSetupReshowTapped: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            MapScreen(
                viewModel: mapViewModel,
                tripStore: tripStore,
                settingsStore: settingsStore,
                onSearchTapped: onSearchTapped
            )
            .background(VelocityColor.surface)

            if showTripSetupReshowCTA {
                Button {
                    onTripSetupReshowTapped()
                } label: {
                    HStack(spacing: VelocitySpacing.sm) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Trip setup")
                                .font(VelocityFontStyle.body(13))
                                .foregroundStyle(VelocityColor.onSurfaceVariant)
                            Text(tripStore.session.destination?.title ?? "")
                                .font(VelocityFontStyle.body(15))
                                .foregroundStyle(VelocityColor.onSurface)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, VelocitySpacing.md)
                    .padding(.vertical, 10)
                    .background(VelocityColor.surfaceContainerHighest.opacity(0.92))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, VelocitySpacing.md)
                .padding(.bottom, VelocitySpacing.lg + VelocitySpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(VelocityColor.surface, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Home")
                    .font(VelocityFontStyle.title(17))
                    .foregroundStyle(VelocityColor.onSurface)
            }
        }
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
            showTripSetupReshowCTA: false,
            onTripSetupReshowTapped: {}
        )
    }
}
