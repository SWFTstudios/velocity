//
//  MapControlsView.swift
//  Velocity
//

import SwiftUI

struct MapControlsView: View {
    let mapDisplayType: MapDisplayType
    let isFollowingUser: Bool
    let isNightMode: Bool
    let onCycleMapType: () -> Void
    let onCenterOrFollowToggle: () -> Void
    let onToggleTheme: () -> Void
    let onOpenSounds: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: VelocitySpacing.sm) {
            mapButton(icon: mapDisplayType.iconName, isActive: true, action: onCycleMapType)
                .accessibilityLabel("Cycle map type")

            mapButton(
                icon: isFollowingUser ? "location.fill.viewfinder" : "location.fill",
                isActive: isFollowingUser,
                action: onCenterOrFollowToggle
            )
            .accessibilityLabel(isFollowingUser ? "Stop following and free roam" : "Center on your location and follow")

            mapButton(
                icon: isNightMode ? "moon.fill" : "sun.max.fill",
                isActive: isNightMode,
                action: onToggleTheme
            )
            .accessibilityLabel(isNightMode ? "Switch to day map theme" : "Switch to night map theme")

            mapButton(icon: "waveform", isActive: false, action: onOpenSounds)
                .accessibilityLabel("Sleep sounds")

            mapButton(icon: "gearshape.fill", isActive: false, action: onOpenSettings)
                .accessibilityLabel("Settings")
        }
        .animation(.easeInOut(duration: 0.22), value: isFollowingUser)
        .animation(.easeInOut(duration: 0.22), value: isNightMode)
    }

    private func mapButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isActive ? VelocityColor.primary : VelocityColor.onSurface)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(VelocityColor.surfaceContainerHigh.opacity(0.96))
                )
                .overlay(
                    Circle()
                        .stroke(
                            isActive ? VelocityColor.primary.opacity(0.75) : VelocityColor.outlineVariantMuted.opacity(0.9),
                            lineWidth: isActive ? 2.2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive ? 1.03 : 1)
        .animation(.easeInOut(duration: 0.22), value: isActive)
    }
}
