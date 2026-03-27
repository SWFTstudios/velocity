//
//  AlarmSetupView.swift
//  Velocity
//

import SwiftUI

struct AlarmSetupView: View {
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore
    @Bindable var mapViewModel: MapViewModel
    var onDismiss: (() -> Void)?
    var onStartTrip: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VelocitySpacing.lg) {
                sheetHeader
                destinationCard
                transitModePicker
                quietModeRow
                startButton
            }
            .padding(VelocitySpacing.md)
        }
        .background(VelocityColor.surface.ignoresSafeArea())
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
        .padding(.bottom, 4)
    }

    private var destinationCard: some View {
        HStack(alignment: .top, spacing: VelocitySpacing.md) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(VelocityColor.surfaceContainerHighest)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "mappin.circle.fill")
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
                HStack(spacing: 6) {
                    Button {
                        tripStore.clearDestination()
                        onDismiss?()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear destination")
                    Text(tripStore.session.destination?.subtitle ?? "Search from Home")
                        .font(VelocityFontStyle.body(13))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                }
            }
            Spacer(minLength: 8)
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "pencil")
            }
            .accessibilityLabel("Edit destination")
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

    private var quietModeRow: some View {
        HStack(alignment: .top, spacing: VelocitySpacing.md) {
            Image(systemName: "sun.max.fill")
                .foregroundStyle(VelocityColor.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Quiet mode override")
                    .font(VelocityFontStyle.title(15))
                    .foregroundStyle(VelocityColor.onSurface)
                Text("Velocity will play your selected alarm at full volume when it’s time to wake.")
                    .font(VelocityFontStyle.body(13))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
            }
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
    }

    private var startButton: some View {
        Button("Start trip") {
            if let origin = mapViewModel.currentUserCoordinate {
                tripStore.setOriginCoordinateIfNeeded(origin)
            }
            tripStore.startTrip()
            onStartTrip?()
        }
        .buttonStyle(VelocityPrimaryButtonStyle())
        .disabled(tripStore.session.destination == nil)
        .opacity(tripStore.session.destination == nil ? 0.5 : 1)
    }
}

#Preview {
    NavigationStack {
        let store = TripSessionStore()
        AlarmSetupView(
            tripStore: store,
            settingsStore: UserSettingsStore(),
            mapViewModel: MapViewModel(tripStore: store, services: .preview),
            onDismiss: nil,
            onStartTrip: nil
        )
    }
}
