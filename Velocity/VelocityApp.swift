//
//  VelocityApp.swift
//  Velocity
//
//  Created by Elombe.Kisala on 3/24/26.
//

import SwiftUI

@main
struct VelocityApp: App {
    @State private var tripSessionStore = TripSessionStore()
    @State private var userSettingsStore = UserSettingsStore()

    var body: some Scene {
        WindowGroup {
            MainTabView(tripStore: tripSessionStore, settingsStore: userSettingsStore)
                .preferredColorScheme(userSettingsStore.preferredColorScheme)
        }
    }
}
