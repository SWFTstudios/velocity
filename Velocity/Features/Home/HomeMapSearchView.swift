//
//  HomeMapSearchView.swift
//  Velocity
//

import CoreLocation
import MapKit
import SwiftUI

struct HomeMapSearchView: View {
    @Bindable var tripStore: TripSessionStore
    @Binding var path: NavigationPath

    @State private var searchQuery = ""
    @FocusState private var searchFocused: Bool

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer

            VStack(alignment: .leading, spacing: 0) {
                topChrome
                journeyHeader
                metricScroll
                Spacer(minLength: 120)
            }
            .padding(.top, 8)

            searchBar
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

    private var mapLayer: some View {
        Map(position: .constant(.region(Self.defaultRegion))) {
            Annotation("Wake zone", coordinate: CLLocationCoordinate2D(latitude: 51.515, longitude: -0.12)) {
                Circle()
                    .stroke(VelocityColor.primary, lineWidth: 3)
                    .frame(width: 24, height: 24)
            }
            Annotation("You", coordinate: CLLocationCoordinate2D(latitude: 51.50, longitude: -0.135)) {
                Circle()
                    .fill(Color.blue.opacity(0.9))
                    .frame(width: 14, height: 14)
            }
        }
        .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll))
        .colorScheme(.dark)
        .ignoresSafeArea(edges: .top)
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

    private var searchBar: some View {
        VStack(spacing: VelocitySpacing.sm) {
            HStack(spacing: 12) {
                Circle()
                    .fill(VelocityColor.primary.opacity(0.35))
                    .frame(width: 10, height: 10)
                TextField("Where to?", text: $searchQuery)
                    .focused($searchFocused)
                    .foregroundStyle(VelocityColor.onSurface)
                    .font(VelocityFontStyle.body())
                Spacer(minLength: 8)
                Button {
                    useSampleDestination()
                } label: {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundStyle(VelocityColor.primary)
                }
                .accessibilityLabel("Use sample destination")
            }
            .padding(.horizontal, VelocitySpacing.md)
            .padding(.vertical, 14)
            .background(VelocityColor.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.control, style: .continuous))

            HStack(spacing: VelocitySpacing.md) {
                Button("Plan wake") {
                    if tripStore.session.destination != nil {
                        path.append(HomeRoute.alarmSetup)
                    } else {
                        useSampleDestination()
                        path.append(HomeRoute.alarmSetup)
                    }
                }
                .buttonStyle(VelocityPrimaryButtonStyle())
            }
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.bottom, VelocitySpacing.lg)
        .background(
            VelocityColor.surface.opacity(0.92)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func useSampleDestination() {
        tripStore.setDestination(
            CommuteDestination(
                title: "St. Pancras International",
                subtitle: "London, United Kingdom",
                latitude: 51.5319,
                longitude: -0.1263
            )
        )
        searchQuery = tripStore.session.destination?.title ?? ""
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
