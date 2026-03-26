//
//  AlarmSetupView.swift
//  Velocity
//

import SwiftUI

struct AlarmSetupView: View {
    @Bindable var tripStore: TripSessionStore
    @Binding var path: NavigationPath

    @State private var thresholdKind: ThresholdKind = .distance
    @State private var distanceKm: Double = 10.5
    @State private var minutesBefore: Double = 15

    private enum ThresholdKind: String, CaseIterable {
        case distance = "Distance"
        case time = "Time"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VelocitySpacing.lg) {
                destinationCard
                transitModePicker
                wakeThresholdSection
                quietModeRow
                startButton
            }
            .padding(VelocitySpacing.md)
        }
        .background(VelocityColor.surface.ignoresSafeArea())
        .navigationTitle("Alarm setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
        .onAppear { syncFromSession() }
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
                        if !path.isEmpty {
                            path.removeLast()
                        }
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
                path.removeLast()
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

    private var wakeThresholdSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            Text("Wake-up threshold")
                .font(VelocityFontStyle.title(18))
                .foregroundStyle(VelocityColor.onSurface)
            Text("Choose how early you want to be awakened before reaching your stop.")
                .font(VelocityFontStyle.body(14))
                .foregroundStyle(VelocityColor.onSurfaceVariant)

            Picker("Kind", selection: $thresholdKind) {
                ForEach(ThresholdKind.allCases, id: \.self) { k in
                    Text(k.rawValue).tag(k)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: thresholdKind) { _, new in
                applyThreshold(kind: new)
            }

            VStack(alignment: .leading, spacing: 8) {
                if thresholdKind == .distance {
                    Text(String(format: "%.1f km", distanceKm))
                        .font(VelocityFontStyle.headline(24))
                        .foregroundStyle(VelocityColor.onSurface)
                    Text("RADIUS DISTANCE FROM STOP")
                        .font(VelocityFontStyle.label(10))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                    Slider(value: $distanceKm, in: 1 ... 50, step: 0.5)
                        .tint(VelocityColor.primary)
                        .onChange(of: distanceKm) { _, v in
                            tripStore.setThreshold(.distanceKilometers(v))
                        }
                    HStack {
                        Text("1 KM").font(VelocityFontStyle.label(9)).foregroundStyle(VelocityColor.onSurfaceVariant)
                        Spacer()
                        Text("25 KM").font(VelocityFontStyle.label(9)).foregroundStyle(VelocityColor.onSurfaceVariant)
                        Spacer()
                        Text("50 KM").font(VelocityFontStyle.label(9)).foregroundStyle(VelocityColor.onSurfaceVariant)
                    }
                } else {
                    Text("\(Int(minutesBefore)) min")
                        .font(VelocityFontStyle.headline(24))
                        .foregroundStyle(VelocityColor.onSurface)
                    Text("TIME BEFORE ARRIVAL")
                        .font(VelocityFontStyle.label(10))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                    Slider(value: $minutesBefore, in: 5 ... 120, step: 1)
                        .tint(VelocityColor.primary)
                        .onChange(of: minutesBefore) { _, v in
                            tripStore.setThreshold(.timeBeforeArrival(v * 60))
                        }
                }
            }
            .padding(VelocitySpacing.md)
            .background(VelocityColor.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
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
            tripStore.startTrip()
            path.append(HomeRoute.activeTrip)
        }
        .buttonStyle(VelocityPrimaryButtonStyle())
        .disabled(tripStore.session.destination == nil)
        .opacity(tripStore.session.destination == nil ? 0.5 : 1)
    }

    private func syncFromSession() {
        switch tripStore.session.threshold {
        case let .distanceKilometers(km):
            thresholdKind = .distance
            distanceKm = km
        case let .timeBeforeArrival(t):
            thresholdKind = .time
            minutesBefore = t / 60
        }
    }

    private func applyThreshold(kind: ThresholdKind) {
        switch kind {
        case .distance:
            tripStore.setThreshold(.distanceKilometers(distanceKm))
        case .time:
            tripStore.setThreshold(.timeBeforeArrival(minutesBefore * 60))
        }
    }
}

#Preview {
    NavigationStack {
        AlarmSetupView(tripStore: TripSessionStore(), path: .constant(NavigationPath()))
    }
}
