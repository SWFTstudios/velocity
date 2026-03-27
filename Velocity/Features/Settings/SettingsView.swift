//
//  SettingsView.swift
//  Velocity
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settingsStore: UserSettingsStore

    var body: some View {
        List {
            Section {
                profileCard
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

            Section {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(VelocityColor.onPrimaryFixed)
                    VStack(alignment: .leading) {
                        Text("8.4h")
                            .font(VelocityFontStyle.headline(22))
                            .foregroundStyle(VelocityColor.onPrimaryFixed)
                        Text("AVG. SLEEP")
                            .font(VelocityFontStyle.label(10))
                            .foregroundStyle(VelocityColor.onPrimaryFixed.opacity(0.85))
                    }
                    Spacer()
                }
                .padding(VelocitySpacing.md)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                        .fill(LinearGradient.velocityPrimaryCTA)
                )
                .listRowBackground(Color.clear)
            }

            Section("App preferences") {
                Toggle(isOn: Binding(
                    get: { settingsStore.settings.notificationsEnabled },
                    set: { settingsStore.setNotifications($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications")
                        Text("Smart wake-up and reminders")
                            .font(.caption)
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                    }
                }
                .tint(VelocityColor.primary)

                Toggle(isOn: Binding(
                    get: { settingsStore.settings.quietModeEnabled },
                    set: { settingsStore.setQuietMode($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quiet mode")
                        Text("Silence all but emergency alarms")
                            .font(.caption)
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                    }
                }

                Picker("Theme", selection: Binding(
                    get: { settingsStore.settings.colorway },
                    set: { settingsStore.setColorway($0) }
                )) {
                    ForEach(AppColorway.allCases, id: \.self) { colorway in
                        Text(colorway.displayName).tag(colorway)
                    }
                }

                Picker("Distance unit", selection: Binding(
                    get: { settingsStore.settings.measurementUnit },
                    set: { settingsStore.setMeasurementUnit($0) }
                )) {
                    ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

                let minMiles: Double = 0.1
                let maxMiles: Double = 10.0
                let milesToKm = 1.609344
                let displayStep: Double = 0.1

                let unit = settingsStore.settings.measurementUnit
                let sliderRange: ClosedRange<Double> = unit == .miles
                    ? (minMiles ... maxMiles)
                    : (minMiles * milesToKm ... maxMiles * milesToKm)

                let radiusDisplayValue: Double = {
                    let km = settingsStore.settings.defaultWakeRadiusKilometers
                    return unit == .miles ? km / milesToKm : km
                }()

                VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
                    Text("Default wake radius")
                        .font(VelocityFontStyle.title(16))
                        .foregroundStyle(VelocityColor.onSurface)

                    Text(String(format: "%.1f %@", radiusDisplayValue, unit.distanceSuffix.uppercased()))
                        .font(VelocityFontStyle.headline(20))
                        .foregroundStyle(VelocityColor.onSurface)

                    Slider(
                        value: Binding(
                            get: {
                                let km = settingsStore.settings.defaultWakeRadiusKilometers
                                return unit == .miles ? km / milesToKm : km
                            },
                            set: { newValue in
                                let km = unit == .miles ? newValue * milesToKm : newValue
                                settingsStore.setDefaultWakeRadiusKilometers(km)
                            }
                        ),
                        in: sliderRange,
                        step: displayStep
                    )
                    .tint(VelocityColor.primary)

                    HStack {
                        Text(unit == .miles ? "0.1 MI" : String(format: "%.1f KM", minMiles * milesToKm))
                        .font(VelocityFontStyle.label(11))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                        Spacer()
                        Text(unit == .miles ? "10 MI" : String(format: "%.1f KM", maxMiles * milesToKm))
                        .font(VelocityFontStyle.label(11))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                    }
                }
                .padding(.vertical, VelocitySpacing.sm)
            }

            #if DEBUG
            Section("Developer") {
                NavigationLink("Stitch design exports") {
                    StitchExportsRootView()
                }
            }
            #endif
        }
        .scrollContentBackground(.hidden)
        .background(VelocityColor.surface.ignoresSafeArea())
        .navigationTitle("Settings")
    }

    private var profileCard: some View {
        HStack(spacing: VelocitySpacing.md) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(VelocityColor.primary, lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                    }
                Image(systemName: "pencil.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(VelocityColor.surface, VelocityColor.primary)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("COMMUTER")
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.primary)
                Text("You")
                    .font(VelocityFontStyle.title(18))
                    .foregroundStyle(VelocityColor.onSurface)
                Text("Resting with Velocity")
                    .font(VelocityFontStyle.body(13))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
            }
            Spacer()
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        SettingsView(settingsStore: UserSettingsStore())
    }
}
