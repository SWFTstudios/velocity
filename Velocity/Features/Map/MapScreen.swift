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
    var showTripProgressReshowCTA: Bool = false
    var onTripProgressReshowTapped: () -> Void = {}
    @State private var pendingPressPoint: CGPoint?

    private var showsPlanningSummaryBar: Bool {
        tripStore.session.status == .planning && tripStore.session.destination != nil
    }

    private var showsActiveTripMapChrome: Bool {
        switch tripStore.session.status {
        case .active, .paused, .waking: true
        default: false
        }
    }

    private var activeRouteCoords: [CLLocationCoordinate2D] {
        viewModel.activeRouteCoordinates
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

                if activeRouteCoords.count >= 2 {
                    MapPolyline(coordinates: activeRouteCoords)
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
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { _, height in
            viewModel.mapViewportHeightPoints = height
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) { mapControls }
        .overlay(alignment: .top) {
            if showsActiveTripMapChrome {
                activeTripSummaryCard
                    .padding(.top, 8)
            }
        }
        .overlay(alignment: .bottom) { bottomStack }
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

    private var bottomStack: some View {
        VStack(spacing: VelocitySpacing.sm) {
            if showsActiveTripMapChrome {
                Text(tripStore.session.wakeRadiusBadgeText)
                    .font(VelocityFontStyle.label(11))
                    .foregroundStyle(VelocityColor.onSurface)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(VelocityColor.surfaceContainer.opacity(0.92))
                    .clipShape(Capsule())

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
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                activeTripControls
            }

            bottomPanel
        }
        .animation(.easeInOut(duration: 0.2), value: showTripProgressReshowCTA)
    }

    private var activeTripSummaryCard: some View {
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
                activeTripEtaColumn
                activeTripDistanceColumn
            }
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainer.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
        .padding(.horizontal, VelocitySpacing.md)
    }

    private var activeTripEtaColumn: some View {
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

    private var activeTripDistanceColumn: some View {
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

    private var activeTripControls: some View {
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
        .padding(.bottom, VelocitySpacing.sm)
        .padding(.top, VelocitySpacing.sm)
        .background(VelocityColor.surface.opacity(0.94))
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
                        if viewModel.activeRouteCoordinates.count >= 2 {
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
