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

    var body: some View {
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
            onOpenTripSetup: {}
        )
    }
}
