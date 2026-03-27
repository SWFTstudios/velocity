//
//  VelocityApp.swift
//  Velocity
//
//  Created by Elombe.Kisala on 3/24/26.
//

import SwiftUI

@main
struct VelocityApp: App {
    @State private var tripSessionStore: TripSessionStore
    @State private var userSettingsStore = UserSettingsStore()

    init() {
        let alarmConfig = AlarmCallConfig.load()
        let alarmService: AlarmCallService = {
            guard let alarmConfig else { return NoopAlarmCallService() }
            return HttpAlarmCallService(config: alarmConfig)
        }()
        _tripSessionStore = State(
            initialValue: TripSessionStore(
                alarmCallService: alarmService,
                alarmRecipientNumber: alarmConfig?.defaultToPhoneNumber
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(tripStore: tripSessionStore, settingsStore: userSettingsStore)
                .preferredColorScheme(userSettingsStore.preferredColorScheme)
        }
    }
}
