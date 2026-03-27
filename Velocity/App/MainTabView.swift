//
//  MainTabView.swift
//  Velocity
//

import SwiftUI

struct MainTabView: View {
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore
    @State private var historyViewModel: HistoryViewModel

    init(tripStore: TripSessionStore, settingsStore: UserSettingsStore) {
        self.tripStore = tripStore
        self.settingsStore = settingsStore
        _historyViewModel = State(initialValue: HistoryViewModel(historyStore: tripStore.historyStore))
    }

    var body: some View {
        TabView {
            HomeTabRootView(tripStore: tripStore, settingsStore: settingsStore)
                .tabItem { Label("Home", systemImage: "map") }

            NavigationStack {
                SleepSoundsLibraryView()
            }
            .tabItem { Label("Sounds", systemImage: "waveform") }

            NavigationStack {
                HistoryView(viewModel: historyViewModel)
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
