//
//  ActiveTripMapView.swift
//  Velocity
//

import MapKit
import SwiftUI

struct ActiveTripMapView: View {
    @Bindable var tripStore: TripSessionStore
    @Binding var path: NavigationPath
    @Bindable var mapViewModel: MapViewModel
    let showTripProgressReshowCTA: Bool
    let onTripProgressReshowTapped: () -> Void

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.51, longitude: -0.125),
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: Binding(
                get: {
                    if case .automatic = mapViewModel.cameraPosition {
                        return .region(Self.defaultRegion)
                    }
                    return mapViewModel.cameraPosition
                },
                set: { mapViewModel.cameraPosition = $0 }
            )) {
                if !mapViewModel.activeRouteCoordinates.isEmpty {
                    MapPolyline(coordinates: mapViewModel.activeRouteCoordinates)
                        .stroke(VelocityColor.primary, lineWidth: 4)
                }
            }
            .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                tripCard
                Spacer()
                controls
            }
            .padding(.top, 8)

            Text(tripStore.session.wakeRadiusBadgeText)
                .font(VelocityFontStyle.label(11))
                .foregroundStyle(VelocityColor.onSurface)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(VelocityColor.surfaceContainer.opacity(0.92))
                .clipShape(Capsule())
                .padding(.bottom, 200)

            if showTripProgressReshowCTA {
                Button {
                    onTripProgressReshowTapped()
                } label: {
                    HStack(spacing: VelocitySpacing.sm) {
                        Image(systemName: "timer.circle.fill")
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                        Text("Trip progress")
                            .font(VelocityFontStyle.body(14))
                            .foregroundStyle(VelocityColor.onSurface)
                    }
                    .padding(.horizontal, VelocitySpacing.md)
                    .padding(.vertical, 10)
                    .background(VelocityColor.surfaceContainerHighest.opacity(0.92))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 260)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .background(VelocityColor.surface)
        .navigationTitle("Sleep map / route")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(VelocityColor.surface, for: .navigationBar)
        .onAppear {
            mapViewModel.onSceneActive()
            mapViewModel.fitCameraToRoute()
        }
        .onDisappear {
            mapViewModel.onSceneInactive()
        }
    }

    private var tripCard: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            HStack {
                Text("NEXT STOP")
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.primary)
                Spacer()
                Text(tripStore.session.onTrackLabel)
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.onSurface)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(VelocityColor.surfaceContainerHighest)
                    .clipShape(Capsule())
            }
            Text(tripStore.session.nextStopName)
                .font(VelocityFontStyle.headline(22))
                .foregroundStyle(VelocityColor.onSurface)
            HStack(spacing: VelocitySpacing.lg) {
                etaColumn
                distanceColumn
            }
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainer.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
        .padding(.horizontal, VelocitySpacing.md)
    }

    private var etaColumn: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .foregroundStyle(VelocityColor.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("ETA")
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                Text(tripStore.session.etaDisplay)
                    .font(VelocityFontStyle.title(16))
                    .foregroundStyle(VelocityColor.onSurface)
            }
        }
    }

    private var distanceColumn: some View {
        HStack(spacing: 10) {
            Image(systemName: "ruler.fill")
                .foregroundStyle(VelocityColor.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Distance")
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                Text(tripStore.session.distanceDisplay)
                    .font(VelocityFontStyle.title(16))
                    .foregroundStyle(VelocityColor.onSurface)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: VelocitySpacing.sm) {
            HStack(spacing: VelocitySpacing.md) {
                Button {
                    if tripStore.session.status == .active {
                        tripStore.pauseTrip()
                    } else if tripStore.session.status == .paused {
                        tripStore.resumeTrip()
                    }
                } label: {
                    Label(
                        tripStore.session.status == .paused ? "Resume" : "Pause",
                        systemImage: tripStore.session.status == .paused ? "play.fill" : "pause.fill"
                    )
                    .font(VelocityFontStyle.title(15))
                    .foregroundStyle(VelocityColor.onSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(VelocityColor.surfaceContainerHighest)
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
                }

                Button {
                    tripStore.completeTrip(wasAwakened: false)
                    path = NavigationPath()
                } label: {
                    Label("End trip", systemImage: "stop.fill")
                        .font(VelocityFontStyle.title(15))
                        .foregroundStyle(VelocityColor.onPrimaryFixed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous)
                                .fill(LinearGradient.velocityPrimaryCTA)
                        )
                }
            }

            Button("Simulate approaching destination") {
                tripStore.triggerWake(reason: .manual)
            }
            .font(VelocityFontStyle.body(14))
            .foregroundStyle(VelocityColor.secondary)
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.bottom, VelocitySpacing.xl)
        .padding(.top, VelocitySpacing.sm)
        .background(VelocityColor.surface.opacity(0.94).ignoresSafeArea(edges: .bottom))
    }

}

#Preview {
    NavigationStack {
        let store = TripSessionStore()
        ActiveTripMapView(
            tripStore: store,
            path: .constant(NavigationPath()),
            mapViewModel: MapViewModel(tripStore: store, services: .preview),
            showTripProgressReshowCTA: false,
            onTripProgressReshowTapped: {}
        )
    }
}
