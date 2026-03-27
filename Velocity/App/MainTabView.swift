//
//  MainTabView.swift
//  Velocity
//

import SwiftUI

struct MainTabView: View {
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore
    @State private var historyViewModel: HistoryViewModel
    @State private var sleepSoundsViewModel: SleepSoundsViewModel
    @State private var showsSounds = false
    @State private var showsSettings = false

    init(tripStore: TripSessionStore, settingsStore: UserSettingsStore, sleepAudioService: SleepAudioService) {
        self.tripStore = tripStore
        self.settingsStore = settingsStore
        _historyViewModel = State(initialValue: HistoryViewModel(historyStore: tripStore.historyStore))
        _sleepSoundsViewModel = State(
            initialValue: SleepSoundsViewModel(
                settingsStore: settingsStore,
                audioService: sleepAudioService
            )
        )
    }

    var body: some View {
        HomeTabRootView(
            tripStore: tripStore,
            settingsStore: settingsStore,
            onOpenSounds: { showsSounds = true },
            onOpenSettings: { showsSettings = true }
        )
        .tint(VelocityColor.primary)
        .sheet(isPresented: $showsSounds) {
            NavigationStack {
                SleepSoundsLibraryView(viewModel: sleepSoundsViewModel)
            }
        }
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsView(settingsStore: settingsStore, historyViewModel: historyViewModel)
            }
        }
    }
}

#Preview {
    MainTabView(
        tripStore: TripSessionStore(),
        settingsStore: UserSettingsStore(),
        sleepAudioService: NoopSleepAudioService()
    )
}
