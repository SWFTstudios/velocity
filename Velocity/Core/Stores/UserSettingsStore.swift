//
//  UserSettingsStore.swift
//  Velocity
//

import SwiftUI

private enum UserSettingsKeys {
    static let payload = "velocity.userSettings.v1"
}

@Observable
@MainActor
final class UserSettingsStore {
    var settings: UserSettings

    init() {
        if let data = UserDefaults.standard.data(forKey: UserSettingsKeys.payload),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }

    init(settings: UserSettings) {
        self.settings = settings
    }

    var preferredColorScheme: ColorScheme? {
        switch settings.theme {
        case .system: nil
        case .light: .light
        case .darkOnly: .dark
        }
    }

    func setNotifications(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
        persist()
    }

    func setQuietMode(_ enabled: Bool) {
        settings.quietModeEnabled = enabled
        persist()
    }

    func setTheme(_ theme: AppTheme) {
        settings.theme = theme
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: UserSettingsKeys.payload)
    }
}
