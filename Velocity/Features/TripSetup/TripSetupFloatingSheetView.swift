//
//  TripSetupFloatingSheetView.swift
//  Velocity
//

import SwiftUI

/// Compact trip setup sheet that floats over the map (<= half screen height).
/// Live-updates the wake radius on the map via `tripStore.session.threshold`.
struct TripSetupFloatingSheetView: View {
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore
    @Bindable var mapViewModel: MapViewModel

    var onDismiss: (() -> Void)?
    var onConfirmTrip: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.lg) {
            sheetHeader

            destinationCard

            transitModePicker

            wakeRadiusSection

            confirmButton
        }
        .padding(VelocitySpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VelocityColor.surface.ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onAppear {
            // Focus the user + destination behind the sheet for better context.
            mapViewModel.fitCameraToUserAndDestination()
        }
    }

    private var sheetHeader: some View {
        HStack(alignment: .center) {
            Text("Trip setup")
                .font(VelocityFontStyle.title(18))
                .foregroundStyle(VelocityColor.onSurface)

            Spacer()

            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Dismiss trip setup")
        }
    }

    private var destinationCard: some View {
        HStack(alignment: .top, spacing: VelocitySpacing.md) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(VelocityColor.surfaceContainerHighest)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: tripStore.session.mode.mapSymbolName)
                        .font(.title2)
                        .foregroundStyle(VelocityColor.primary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("DESTINATION")
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                Text(tripStore.session.destination?.title ?? "Choose a stop")
                    .font(VelocityFontStyle.title(18))
                    .foregroundStyle(VelocityColor.onSurface)
                    .lineLimit(1)
                Text(tripStore.session.destination?.subtitle ?? "")
                    .font(VelocityFontStyle.body(13))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
    }

    private var transitModePicker: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            Text("Transit mode")
                .font(VelocityFontStyle.title(16))
                .foregroundStyle(VelocityColor.onSurface)

            Picker("Mode", selection: Binding(
                get: { tripStore.session.mode },
                set: { tripStore.setTransitMode($0) }
            )) {
                ForEach(TransitMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var wakeRadiusSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            Text("WAKE RADIUS")
                .font(VelocityFontStyle.label(10))
                .foregroundStyle(VelocityColor.onSurfaceVariant)

            Text(radiusValueDisplay)
                .font(VelocityFontStyle.title(17))
                .foregroundStyle(VelocityColor.onSurface)

            Slider(value: radiusSliderBinding, in: sliderRange, step: 0.1)
                .tint(VelocityColor.primary)

            HStack {
                Text(minRadiusLabel)
                    .font(VelocityFontStyle.label(9))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                Spacer()
                Text(maxRadiusLabel)
                    .font(VelocityFontStyle.label(9))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
            }
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainerHighest.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
    }

    private var confirmButton: some View {
        Button {
            if let origin = mapViewModel.currentUserCoordinate {
                tripStore.setOriginCoordinateIfNeeded(origin)
            }
            tripStore.startTrip()
            onConfirmTrip?()
        } label: {
            Text("Confirm trip")
        }
        .buttonStyle(VelocityPrimaryButtonStyle())
        .disabled(tripStore.session.destination == nil)
        .opacity(tripStore.session.destination == nil ? 0.6 : 1.0)
    }

    private var radiusSliderBinding: Binding<Double> {
        Binding(
            get: {
                let km = tripStore.session.threshold.distanceKilometersValue ?? 10.5
                return settingsStore.settings.measurementUnit == .miles ? km * 0.621371 : km
            },
            set: { newValue in
                let km = settingsStore.settings.measurementUnit == .miles ? newValue / 0.621371 : newValue
                tripStore.setThreshold(.distanceKilometers(km))
            }
        )
    }

    private var sliderRange: ClosedRange<Double> {
        // Wake radius range: 0.1–10 miles (converted to km equivalent).
        let minMiles: Double = 0.1
        let maxMiles: Double = 10.0
        let milesToKm = 1.609344
        if settingsStore.settings.measurementUnit == .miles {
            return minMiles ... maxMiles
        } else {
            return (minMiles * milesToKm) ... (maxMiles * milesToKm)
        }
    }

    private var minRadiusLabel: String {
        // Labels are rounded for display consistency.
        settingsStore.settings.measurementUnit == .miles ? "0.1 MI" : "0.2 KM"
    }

    private var maxRadiusLabel: String {
        // 10 miles => ~16.1 km (rounded).
        settingsStore.settings.measurementUnit == .miles ? "10 MI" : "16.1 KM"
    }

    private var radiusValueDisplay: String {
        let km = tripStore.session.threshold.distanceKilometersValue ?? 10.5
        let value = settingsStore.settings.measurementUnit == .miles ? km * 0.621371 : km
        return String(format: "%.1f %@", value, settingsStore.settings.measurementUnit.distanceSuffix.uppercased())
    }
}

#Preview {
    TripSetupFloatingSheetView(
        tripStore: TripSessionStore(),
        settingsStore: UserSettingsStore(),
        mapViewModel: MapViewModel(tripStore: TripSessionStore(), services: .preview),
        onDismiss: nil,
        onConfirmTrip: nil
    )
}

