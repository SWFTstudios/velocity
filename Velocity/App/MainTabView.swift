//
//  MainTabView.swift
//  Velocity
//

import SwiftUI

struct MainTabView: View {
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore

    var body: some View {
        TabView {
            HomeTabRootView(tripStore: tripStore)
                .tabItem { Label("Home", systemImage: "map") }

            NavigationStack {
                SleepSoundsLibraryView()
            }
            .tabItem { Label("Sounds", systemImage: "waveform") }

            NavigationStack {
                HistoryPlaceholderView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            NavigationStack {
                SettingsView(settingsStore: settingsStore)
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(VelocityColor.primary)
    }
}

#Preview {
    MainTabView(
        tripStore: TripSessionStore(),
        settingsStore: UserSettingsStore()
    )
}
