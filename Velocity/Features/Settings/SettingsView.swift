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
                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("Theme", selection: Binding(
                    get: { settingsStore.settings.theme },
                    set: { settingsStore.setTheme($0) }
                )) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
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
