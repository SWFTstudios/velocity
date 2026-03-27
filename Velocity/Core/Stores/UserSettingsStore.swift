//
//  UserSettingsStore.swift
//  Velocity
//

import SwiftUI

enum UserSettingsKeys {
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

    func setColorway(_ colorway: AppColorway) {
        settings.colorway = colorway
        persist()
    }

    func setMeasurementUnit(_ unit: MeasurementUnit) {
        settings.measurementUnit = unit
        persist()
    }

    func setDefaultWakeRadiusKilometers(_ kilometers: Double) {
        settings.defaultWakeRadiusKilometers = kilometers
        persist()
    }

    nonisolated static func currentMeasurementUnit() -> MeasurementUnit {
        guard let data = UserDefaults.standard.data(forKey: UserSettingsKeys.payload),
              let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return .kilometers
        }
        return decoded.measurementUnit
    }

    nonisolated static func currentDefaultWakeRadiusKilometers() -> Double {
        guard let data = UserDefaults.standard.data(forKey: UserSettingsKeys.payload),
              let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return 0.3 * 1.609344 // 0.3 mi -> km
        }
        return decoded.defaultWakeRadiusKilometers
    }

    nonisolated static func currentColorway() -> AppColorway {
        guard let data = UserDefaults.standard.data(forKey: UserSettingsKeys.payload),
              let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return .midnightCalm
        }
        return decoded.colorway
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: UserSettingsKeys.payload)
    }
}
