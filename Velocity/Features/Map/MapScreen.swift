//
//  MapScreen.swift
//  Velocity
//
//  SwiftUI-first map: annotations, route polyline, and a compact bottom panel
//  for search and summaries. Heavy work stays in MapViewModel and services.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapScreen: View {
    @Bindable var viewModel: MapViewModel
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore
    var onSearchTapped: () -> Void
    var onOpenSounds: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onOpenTripSetup: () -> Void = {}
    @State private var pendingPressPoint: CGPoint?

    private var showsPlanningSummaryBar: Bool {
        tripStore.session.status == .planning && tripStore.session.destination != nil
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $viewModel.cameraPosition) {
                UserAnnotation()

                if let dest = viewModel.displayDestinationCoordinate {
                    if tripStore.session.status == .planning {
                        Annotation("Destination", coordinate: dest) {
                            DraggableDestinationAnnotation(
                                proxy: proxy,
                                viewModel: viewModel,
                                symbolName: tripStore.session.mode.mapSymbolName
                            )
                        }
                    } else {
                        Annotation("Destination", coordinate: dest) {
                            ZStack {
                                Circle()
                                    .fill(VelocityColor.surfaceContainerHighest.opacity(0.96))
                                    .frame(width: 28, height: 28)
                                Circle()
                                    .stroke(VelocityColor.primary, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                                Image(systemName: tripStore.session.mode.mapSymbolName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(VelocityColor.primary)
                            }
                                .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                                .accessibilityLabel("Destination")
                        }
                    }

                    if case let .distanceKilometers(km) = tripStore.session.threshold {
                        let meters = max(km * 1000, 100)
                        MapCircle(center: dest, radius: meters)
                            .foregroundStyle(VelocityColor.primary.opacity(0.12))
                            .stroke(VelocityColor.primary.opacity(0.55), lineWidth: 2)
                    }
                }

                if let route = viewModel.currentRoute {
                    MapPolyline(coordinates: route.polylineCoordinates)
                        .stroke(VelocityColor.primary, lineWidth: 5)
                }
            }
            .mapStyle(configuredMapStyle)
            .preferredColorScheme(viewModel.isNightModeActive ? .dark : .light)
            .onMapCameraChange(frequency: .onEnd) {
                viewModel.userDidManuallyAdjustCamera()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        pendingPressPoint = value.location
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.42)
                    .onEnded { _ in
                        guard tripStore.session.status == .idle || tripStore.session.status == .planning else { return }
                        guard let point = pendingPressPoint else { return }
                        guard let coordinate = proxy.convert(point, from: .local) else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.commitLongPressDestination(at: coordinate)
                        }
                    }
            )
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) { mapControls }
        .overlay(alignment: .bottom) { bottomPanel }
        .overlay(alignment: .top) {
            if let notice = viewModel.reducedAccuracyNotice {
                Text(notice)
                    .font(VelocityFontStyle.body(12))
                    .foregroundStyle(VelocityColor.onSurface)
                    .padding(VelocitySpacing.sm)
                    .background(VelocityColor.surfaceContainerHighest.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.control, style: .continuous))
                    .padding(.top, 56)
                    .padding(.horizontal, VelocitySpacing.md)
            }
        }
        .task {
            viewModel.onSceneActive()
        }
        .onDisappear {
            viewModel.onSceneInactive()
        }
    }

    private var mapControls: some View {
        MapControlsView(
            mapDisplayType: viewModel.mapDisplayType,
            isFollowingUser: viewModel.isFollowUserActive,
            isNightMode: viewModel.isNightModeActive,
            onCycleMapType: { viewModel.cycleMapDisplayType() },
            onCenterOrFollowToggle: {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if viewModel.isFollowUserActive {
                        // Currently following: tap to stop following/free roam.
                        viewModel.enterBrowseMode()
                    } else if tripStore.session.destination != nil {
                        // Destination/trip selected: center on the trip context first, then enable follow mode.
                        if viewModel.currentRoute != nil {
                            viewModel.fitCameraToRoute()
                        } else {
                            viewModel.fitCameraToUserAndDestination()
                        }
                        viewModel.enterFollowUserMode()
                    } else {
                        viewModel.centerOnUser()
                    }
                }
            },
            onToggleTheme: { withAnimation(.easeInOut(duration: 0.22)) { viewModel.toggleMapThemeMode() } },
            onOpenSounds: onOpenSounds,
            onOpenSettings: onOpenSettings
        )
        .padding(.trailing, VelocitySpacing.md)
        .padding(.top, 72)
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            if viewModel.locationAuthorizationStatus == .denied
                || viewModel.locationAuthorizationStatus == .restricted {
                Text("Location access is off. Enable it in Settings to see your position and routes.")
                    .font(VelocityFontStyle.body(12))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                    .padding(.horizontal, VelocitySpacing.sm)
            }

            if showsPlanningSummaryBar {
                planningSummaryBar
            } else if tripStore.session.status == .idle || tripStore.session.status == .planning {
                whereToSearchPill
            }
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.bottom, VelocitySpacing.lg)
        .padding(.top, VelocitySpacing.sm)
    }

    private var whereToSearchPill: some View {
        HStack(spacing: VelocitySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(VelocityColor.onSurfaceVariant)

            Button {
                onSearchTapped()
            } label: {
                HStack(spacing: VelocitySpacing.sm) {
                    Text(viewModel.searchText.isEmpty ? "Where To?" : viewModel.searchText)
                        .foregroundStyle(viewModel.searchText.isEmpty ? VelocityColor.onSurfaceVariant : VelocityColor.onSurface)
                        .font(VelocityFontStyle.body())
                        .lineLimit(1)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.syncSearchQuery("")
                    viewModel.clearDestination()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                        .font(.system(size: 18))
                }
                .accessibilityLabel("Clear search and destination")
            }
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.vertical, 12)
        .background(VelocityColor.surfaceContainerLowest.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }

    private var planningSummaryBar: some View {
        HStack(alignment: .center, spacing: VelocitySpacing.sm) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(VelocityColor.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Destination selected")
                    .font(VelocityFontStyle.body(13))
                    .foregroundStyle(VelocityColor.onSurface)
                Text(distanceLine)
                    .font(VelocityFontStyle.body(12))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
            }

            Spacer(minLength: 8)

            Button {
                onOpenTripSetup()
            } label: {
                Text("Confirm trip")
                    .font(VelocityFontStyle.body(14))
                    .fontWeight(.semibold)
                    .foregroundStyle(VelocityColor.onPrimaryFixed)
                    .padding(.horizontal, VelocitySpacing.md)
                    .padding(.vertical, 10)
                    .background(VelocityColor.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.clearDestination()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
            }
            .accessibilityLabel("Clear destination")
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.vertical, 12)
        .background(VelocityColor.surfaceContainer.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(VelocityColor.outlineVariantMuted.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 12, y: 4)
    }

    private var distanceLine: String {
        let dist = tripStore.session.distanceDisplay
        if !dist.isEmpty && dist != "—" {
            return dist
        }
        if let title = tripStore.session.destination?.title {
            return title
        }
        return "Calculating route…"
    }

    private var configuredMapStyle: MapStyle {
        switch viewModel.mapDisplayType {
        case .standard:
            return .standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll)
        case .hybrid:
            return .hybrid(elevation: .realistic, pointsOfInterest: .excludingAll)
        case .imagery:
            return .imagery(elevation: .realistic)
        }
    }
}

#Preview {
    MapScreenPreviewWrapper()
}

private struct MapScreenPreviewWrapper: View {
    @State private var tripStore: TripSessionStore
    @State private var viewModel: MapViewModel

    init() {
        let s = TripSessionStore()
        _tripStore = State(initialValue: s)
        _viewModel = State(initialValue: MapViewModel(tripStore: s, services: .preview))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MapScreen(viewModel: viewModel, tripStore: tripStore, settingsStore: UserSettingsStore(), onSearchTapped: {})
        }
    }
}
