//
//  WakeAlertView.swift
//  Velocity
//

import SwiftUI

struct WakeAlertView: View {
    @Bindable var tripStore: TripSessionStore
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.xl) {
                progressBar
                bellHero
                headline
                cards
                dismissButton
            }
            .padding(VelocitySpacing.lg)
        }
        .background(
            LinearGradient(
                colors: [VelocityColor.surfaceContainerLowest, VelocityColor.surface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Wake-up alert")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(VelocityColor.surfaceContainerHighest)
                    .frame(height: 4)
                Capsule()
                    .fill(VelocityColor.primary)
                    .frame(width: geo.size.width * 0.72, height: 4)
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Wake sequence progress")
        .accessibilityValue("72 percent")
    }

    private var bellHero: some View {
        ZStack {
            ForEach(0 ..< 3, id: \.self) { ring in
                Circle()
                    .stroke(VelocityColor.primary.opacity(0.15 + Double(ring) * 0.12), lineWidth: 2)
                    .frame(width: 120 + CGFloat(ring * 36), height: 120 + CGFloat(ring * 36))
            }
            Circle()
                .fill(VelocityColor.onPrimaryContainer.opacity(0.5))
                .frame(width: 100, height: 100)
            VStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(VelocityColor.primary)
                Text("WAKE UP SEQUENCE")
                    .font(VelocityFontStyle.label(9))
                    .foregroundStyle(VelocityColor.primary)
            }
        }
        .padding(.vertical, VelocitySpacing.md)
    }

    private var headline: some View {
        VStack(spacing: VelocitySpacing.sm) {
            Text("Approaching destination")
                .font(VelocityFontStyle.headline(24))
                .foregroundStyle(VelocityColor.onSurface)
                .multilineTextAlignment(.center)
            (
                Text("Your journey is concluding in approximately ")
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                + Text("\(tripStore.session.minutesToDestination) minutes")
                    .foregroundStyle(VelocityColor.primary)
                    .fontWeight(.semibold)
                + Text(".")
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
            )
            .font(VelocityFontStyle.body(16))
            .multilineTextAlignment(.center)
        }
    }

    private var cards: some View {
        VStack(spacing: VelocitySpacing.md) {
            infoCard(
                icon: "mappin.circle.fill",
                label: "CURRENT LOCATION",
                value: tripStore.session.currentLocationLabel
            )
            infoCard(
                icon: "clock.fill",
                label: "ETA",
                value: tripStore.session.etaDisplay
            )
        }
    }

    private func infoCard(icon: String, label: String, value: String) -> some View {
        HStack(spacing: VelocitySpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(VelocityColor.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(VelocityColor.surfaceContainerHighest))
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                Text(value)
                    .font(VelocityFontStyle.title(17))
                    .foregroundStyle(VelocityColor.onSurface)
            }
            Spacer()
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
    }

    private var dismissButton: some View {
        Button("I'm awake") {
            tripStore.endTrip()
            path = NavigationPath()
        }
        .buttonStyle(VelocityPrimaryButtonStyle())
    }
}

#Preview {
    NavigationStack {
        WakeAlertView(tripStore: TripSessionStore(), path: .constant(NavigationPath()))
    }
}
