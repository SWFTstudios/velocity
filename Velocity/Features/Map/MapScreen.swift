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
    var onPlanWake: () -> Void

    var body: some View {
        MapReader { proxy in
            Map(position: $viewModel.cameraPosition) {
                UserAnnotation()

                if let dest = viewModel.displayDestinationCoordinate {
                    Annotation("Destination", coordinate: dest) {
                        DraggableDestinationAnnotation(proxy: proxy, viewModel: viewModel)
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
            .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)
            .onMapCameraChange(frequency: .onEnd) {
                viewModel.userDidManuallyAdjustCamera()
            }
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
                    .padding(.top, 120)
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
        VStack(spacing: VelocitySpacing.sm) {
            Button {
                viewModel.centerOnUser()
            } label: {
                Image(systemName: "location.fill")
                    .frame(width: 44, height: 44)
                    .background(VelocityColor.surfaceContainerLowest.opacity(0.95))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Recenter on your location")

            Button {
                viewModel.toggleFollowUser()
            } label: {
                Image(systemName: viewModel.isFollowUserActive ? "location.fill.viewfinder" : "location.slash")
                    .frame(width: 44, height: 44)
                    .background(
                        viewModel.isFollowUserActive
                            ? VelocityColor.primary.opacity(0.35)
                            : VelocityColor.surfaceContainerLowest.opacity(0.95)
                    )
                    .clipShape(Circle())
            }
            .accessibilityLabel(viewModel.isFollowUserActive ? "Stop following location" : "Follow your location")

            if viewModel.destination != nil {
                Button {
                    viewModel.clearDestination()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .frame(width: 44, height: 44)
                        .background(VelocityColor.surfaceContainerLowest.opacity(0.95))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Clear destination")
            }
        }
        .foregroundStyle(VelocityColor.onSurface)
        .padding(.trailing, VelocitySpacing.md)
        .padding(.top, 160)
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            if viewModel.locationAuthorizationStatus == .denied
                || viewModel.locationAuthorizationStatus == .restricted {
                Text("Location access is off. Enable it in Settings to see your position and routes.")
                    .font(VelocityFontStyle.body(12))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                TextField("Search for a destination", text: $viewModel.searchText)
                    .foregroundStyle(VelocityColor.onSurface)
                    .font(VelocityFontStyle.body())
                    .onChange(of: viewModel.searchText) { _, new in
                        viewModel.syncSearchQuery(new)
                        viewModel.showsSearchSuggestions = !new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.syncSearchQuery("")
                        viewModel.showsSearchSuggestions = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, VelocitySpacing.md)
            .padding(.vertical, 12)
            .background(VelocityColor.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.control, style: .continuous))

            if viewModel.showsSearchSuggestions, !viewModel.searchCompletions.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.searchCompletions) { item in
                            Button {
                                viewModel.selectSearchCompletion(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(VelocityFontStyle.body())
                                        .foregroundStyle(VelocityColor.onSurface)
                                    if !item.subtitle.isEmpty {
                                        Text(item.subtitle)
                                            .font(VelocityFontStyle.body(12))
                                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .padding(.horizontal, VelocitySpacing.md)
                            }
                            Divider().opacity(0.3)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(VelocityColor.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.control, style: .continuous))
            }

            if let dest = viewModel.destination {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DESTINATION")
                        .font(VelocityFontStyle.label(10))
                        .foregroundStyle(VelocityColor.primary)
                    Text(dest.title)
                        .font(VelocityFontStyle.title(17))
                        .foregroundStyle(VelocityColor.onSurface)
                    Text(dest.subtitle)
                        .font(VelocityFontStyle.body(12))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(VelocitySpacing.md)
                .background(VelocityColor.surfaceContainerHighest.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
            }

            if let route = viewModel.currentRoute {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ROUTE")
                            .font(VelocityFontStyle.label(10))
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                        Text(String(format: "%.0f min", route.expectedTravelTime / 60))
                            .font(VelocityFontStyle.title(17))
                            .foregroundStyle(VelocityColor.onSurface)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("DISTANCE")
                            .font(VelocityFontStyle.label(10))
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                        Text(String(format: "%.1f km", route.distance / 1000))
                            .font(VelocityFontStyle.title(17))
                            .foregroundStyle(VelocityColor.onSurface)
                    }
                }
                .padding(VelocitySpacing.md)
                .background(VelocityColor.surfaceContainerHighest.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))

                Button("Clear route") {
                    viewModel.clearRoute()
                    viewModel.enterBrowseMode()
                }
                .font(VelocityFontStyle.body(12))
                .foregroundStyle(VelocityColor.primary)
            }

            if let err = viewModel.routingErrorMessage {
                Text(err)
                    .font(VelocityFontStyle.body(12))
                    .foregroundStyle(.orange)
            }

            Button("Plan wake") {
                onPlanWake()
            }
            .buttonStyle(VelocityPrimaryButtonStyle())
            .disabled(tripStore.session.destination == nil)
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.bottom, VelocitySpacing.lg)
        .padding(.top, VelocitySpacing.sm)
        .background(VelocityColor.surface.opacity(0.94))
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
            MapScreen(viewModel: viewModel, tripStore: tripStore, onPlanWake: {})
        }
    }
}
