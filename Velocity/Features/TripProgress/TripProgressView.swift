//
//  TripProgressView.swift
//  Velocity
//

import SwiftUI

struct TripProgressView: View {
    @Bindable var tripStore: TripSessionStore

    var onDismiss: (() -> Void)?

    @State private var progressVM = TripProgressViewModel()

    var body: some View {
        VStack(spacing: VelocitySpacing.lg) {
            VStack(spacing: VelocitySpacing.sm) {
                Text("Wake progress")
                    .font(VelocityFontStyle.label(12))
                    .foregroundStyle(VelocityColor.onSurface)

                ZStack {
                    TripProgressRingView(progressFraction: progressVM.progressFraction)
                        .frame(width: 210, height: 210)

                    Text(countdownText)
                        .font(VelocityFontStyle.headline(18))
                        .foregroundStyle(VelocityColor.onSurface)
                        .multilineTextAlignment(.center)

                    if tripStore.session.status == .waking {
                        wakeOverlay
                    }
                }
            }

            statusCard

            if tripStore.session.status != .waking {
                endTripButtonCard
            }
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surface.ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onAppear {
            progressVM.updateProgress(for: tripStore)
        }
        .onChange(of: tripStore.session.status) { _, _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                progressVM.updateProgress(for: tripStore)
            }
        }
        .onChange(of: tripStore.session.activeDistanceMeters) { _, _ in
            progressVM.updateProgress(for: tripStore)
        }
        .onChange(of: tripStore.session.activeETASeconds) { _, _ in
            progressVM.updateProgress(for: tripStore)
        }
        .onChange(of: tripStore.session.threshold) { _, _ in
            progressVM.resetBaselines()
            progressVM.updateProgress(for: tripStore)
        }
    }

    private var statusCard: some View {
        let reasonText: String = {
            switch tripStore.session.threshold {
            case .distanceKilometers:
                return "Based on distance to your wake zone."
            case .timeBeforeArrival:
                return "Based on time to destination."
            }
        }()

        return Text(reasonText)
            .font(VelocityFontStyle.body(13))
            .foregroundStyle(VelocityColor.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .padding(.horizontal, VelocitySpacing.md)
    }

    private var endTripButtonCard: some View {
        Button {
            tripStore.completeTrip(wasAwakened: false)
            onDismiss?()
        } label: {
            Text("End trip")
        }
        .buttonStyle(VelocityPrimaryButtonStyle())
    }

    private var wakeOverlay: some View {
        VStack(spacing: VelocitySpacing.sm) {
            Text("Wake now")
                .font(VelocityFontStyle.headline(20))
                .foregroundStyle(VelocityColor.onSurface)
                .multilineTextAlignment(.center)

            Text(wakeCallStatusText)
                .font(VelocityFontStyle.body(13))
                .foregroundStyle(VelocityColor.onSurfaceVariant)
                .multilineTextAlignment(.center)

            Button {
                tripStore.completeTrip(wasAwakened: true)
                onDismiss?()
            } label: {
                Text("I'm awake")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(VelocityPrimaryButtonStyle())

            Button {
                tripStore.completeTrip(wasAwakened: false)
                onDismiss?()
            } label: {
                Text("End trip")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if tripStore.session.alarmCallState == .failed {
                Button {
                    Task { await tripStore.retryAlarmCall() }
                } label: {
                    Text("Retry wake call")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainerHighest.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .frame(maxWidth: 250)
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)
    }

    private var wakeCallStatusText: String {
        switch tripStore.session.alarmCallState {
        case .idle:
            return "Call not started."
        case .calling:
            return "Placing wake call…"
        case .success:
            return "Wake call placed."
        case .failed:
            return "Wake call failed. You can retry."
        case .skippedNotConfigured:
            return "Wake call not configured."
        }
    }

    private var countdownText: String {
        if tripStore.session.status == .waking {
            return "Wake now"
        }

        switch tripStore.session.threshold {
        case let .distanceKilometers(km):
            guard let currentDistanceMeters = tripStore.session.activeDistanceMeters else { return "—" }
            let thresholdMeters = km * 1000
            let remainingMeters = max(0, currentDistanceMeters - thresholdMeters)

            let unit = UserSettingsStore.currentMeasurementUnit()
            switch unit {
            case .kilometers:
                let remainingKm = remainingMeters / 1000
                return String(format: "Wake in %.1f %@", remainingKm, unit.distanceSuffix.uppercased())
            case .miles:
                let remainingMi = remainingMeters / 1609.344
                return String(format: "Wake in %.1f %@", remainingMi, unit.distanceSuffix.uppercased())
            }

        case let .timeBeforeArrival(thresholdSeconds):
            guard let currentETASeconds = tripStore.session.activeETASeconds else { return "—" }
            let remainingSeconds = max(0, currentETASeconds - thresholdSeconds)
            let totalSeconds = Int(remainingSeconds.rounded())
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "Wake in %02d:%02d", minutes, seconds)
        }
    }
}

