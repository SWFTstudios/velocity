//
//  HomeMapSearchView.swift
//  Velocity
//

import SwiftUI

struct HomeMapSearchView: View {
    @Bindable var tripStore: TripSessionStore
    @Binding var path: NavigationPath

    @State private var mapViewModel: MapViewModel

    init(tripStore: TripSessionStore, path: Binding<NavigationPath>) {
        self.tripStore = tripStore
        self._path = path
        _mapViewModel = State(initialValue: MapViewModel(tripStore: tripStore))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MapScreen(
                viewModel: mapViewModel,
                tripStore: tripStore,
                onPlanWake: {
                    guard tripStore.session.destination != nil else { return }
                    path.append(HomeRoute.alarmSetup)
                }
            )

            VStack(alignment: .leading, spacing: 0) {
                topChrome
                journeyHeader
                metricScroll
                Spacer(minLength: 120)
            }
            .padding(.top, 8)
        }
        .background(VelocityColor.surface)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Home")
                    .font(VelocityFontStyle.title(17))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var topChrome: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(VelocityColor.primary)
                Text("Velocity")
                    .font(VelocityFontStyle.title(18))
                    .foregroundStyle(VelocityColor.primary)
            }
            Spacer()
            Button {
                // Notifications — wire later
            } label: {
                Image(systemName: "bell.fill")
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
            }
            .accessibilityLabel("Notifications")
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.bottom, VelocitySpacing.sm)
    }

    private var journeyHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CURRENT JOURNEY")
                .font(VelocityFontStyle.label(10))
                .foregroundStyle(VelocityColor.primary)
                .tracking(1.2)
            Text(tripStore.session.journeyTitle)
                .font(VelocityFontStyle.headline(26))
                .foregroundStyle(VelocityColor.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.bottom, VelocitySpacing.md)
    }

    private var metricScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VelocitySpacing.sm) {
                metricCard(
                    icon: "gauge.with.dots.needle.67percent",
                    label: "ETA",
                    value: tripStore.session.etaDisplay
                )
                metricCard(
                    icon: "moon.fill",
                    label: "PHASES",
                    value: tripStore.session.phasesDisplay
                )
                if let nap = tripStore.session.napEstimateMinutes {
                    metricCard(
                        icon: "bed.double.fill",
                        label: "NAP EST.",
                        value: "\(nap) min"
                    )
                }
            }
            .padding(.horizontal, VelocitySpacing.md)
        }
    }

    private func metricCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(VelocityColor.primary)
            Text(label)
                .font(VelocityFontStyle.label(10))
                .foregroundStyle(VelocityColor.onSurfaceVariant)
            Text(value)
                .font(VelocityFontStyle.title(17))
                .foregroundStyle(VelocityColor.onSurface)
        }
        .padding(VelocitySpacing.md)
        .frame(width: 132, alignment: .leading)
        .background(VelocityColor.surfaceContainerHighest.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        HomeMapSearchView(
            tripStore: TripSessionStore(),
            path: .constant(NavigationPath())
        )
    }
}
