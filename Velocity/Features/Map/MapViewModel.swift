//
//  MapViewModel.swift
//  Velocity
//
//  Owns map camera, search UI state, destination, and route. Location-driven
//  camera moves are throttled (timer) so we do not fight MapKit every time
//  Core Location emits a noisy fix.
//

import Combine
import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftUI

struct MapServices {
    let location: LocationProviding
    let search: SearchProviding
    let geocoding: GeocodingProviding
    let routing: RoutingProviding

    @MainActor
    static var live: MapServices {
        MapServices(
            location: LocationService(),
            search: SearchService(),
            geocoding: GeocodingService(),
            routing: RoutingService()
        )
    }

    #if DEBUG
    @MainActor
    static var preview: MapServices {
        MapServices(
            location: MockLocationService(),
            search: MockSearchService(),
            geocoding: MockGeocodingService(),
            routing: MockRoutingService()
        )
    }
    #endif
}

@Observable
@MainActor
final class MapViewModel {
    private enum PreferenceKey {
        static let mapDisplayType = "map.displayType"
        static let mapTheme = "map.themeMode"
    }

    private let tripStore: TripSessionStore
    private let services: MapServices

    private var location: LocationProviding { services.location }
    private var search: SearchProviding { services.search }
    private var geocoding: GeocodingProviding { services.geocoding }
    private var routing: RoutingProviding { services.routing }

    var cameraPosition: MapCameraPosition = .automatic
    var mapMode: MapMode = .followUser

    var searchText: String = ""
    var searchCompletions: [SearchCompletionModel] = []

    var destination: PlaceResult?
    var dragPreviewCoordinate: CLLocationCoordinate2D?

    var currentRoute: RouteInfo?
    var routingErrorMessage: String?
    var showsSearchSuggestions: Bool = false
    var mapDisplayType: MapDisplayType = .standard
    var mapThemeMode: MapThemeMode = .night
    var lookAroundScene: MKLookAroundScene?
    var isLookAroundLoading: Bool = false

    private var followCameraTimerCancellable: AnyCancellable?
    private var routeGeneration: Int = 0
    private var geocodeGeneration: Int = 0
    /// Ignores `onMapCameraChange` callbacks briefly after we move the camera so follow mode is not cleared by our own animations.
    private var programmaticCameraSuppressUntil: Date = .distantPast

    // Live routing (origin->destination polyline) refresh throttling.
    // SnoozeLane refreshed the polyline when the user moved meaningfully; we
    // mimic that behavior but debounce/threshold MapKit route builds.
    private var routeRefreshDebounceTask: Task<Void, Never>?
    private var lastRouteOriginLocation: CLLocation?
    private var lastRouteBuildAt: Date?
    private var lookAroundGeneration: Int = 0

    // Used to restore map UI state after the trip setup sheet is dismissed.
    private struct TripSetupSheetSnapshot {
        let mapMode: MapMode
        let showsSearchSuggestions: Bool
    }

    private var tripSetupSheetSnapshot: TripSetupSheetSnapshot?

    init(tripStore: TripSessionStore) {
        self.tripStore = tripStore
        self.services = MapServices.live
        hydrateMapPreferences()
        wireSearchPublishing()
    }

    init(tripStore: TripSessionStore, services: MapServices) {
        self.tripStore = tripStore
        self.services = services
        hydrateMapPreferences()
        wireSearchPublishing()
    }

    func beginTripSetupSheetPresentation() {
        tripSetupSheetSnapshot = TripSetupSheetSnapshot(
            mapMode: mapMode,
            showsSearchSuggestions: showsSearchSuggestions
        )
        // Prevent suggestion list from fighting the sheet and keyboard.
        showsSearchSuggestions = false
    }

    func endTripSetupSheetPresentation() {
        guard let snapshot = tripSetupSheetSnapshot else { return }
        mapMode = snapshot.mapMode
        showsSearchSuggestions = snapshot.showsSearchSuggestions
        tripSetupSheetSnapshot = nil
    }

    private func hydrateMapPreferences() {
        if let raw = UserDefaults.standard.string(forKey: PreferenceKey.mapDisplayType),
           let value = MapDisplayType(rawValue: raw) {
            mapDisplayType = value
        }
        if let raw = UserDefaults.standard.string(forKey: PreferenceKey.mapTheme),
           let value = MapThemeMode(rawValue: raw) {
            mapThemeMode = value
        }
    }

    private func wireSearchPublishing() {
        if let pub = services.search as? SearchCompletionPublishing {
            pub.onCompletionsUpdated = { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    self.searchCompletions = self.services.search.completions
                }
            }
        }
    }

    var displayDestinationCoordinate: CLLocationCoordinate2D? {
        dragPreviewCoordinate ?? destination?.coordinate
    }

    var reducedAccuracyNotice: String? {
        guard location.accuracyAuthorization == .reducedAccuracy else { return nil }
        return "Precise location is off. Wake zones may be less accurate until you enable precise location in Settings."
    }

    var isFollowUserActive: Bool {
        mapMode == .followUser
    }

    var locationAuthorizationStatus: CLAuthorizationStatus {
        services.location.authorizationStatus
    }

    var currentUserCoordinate: CLLocationCoordinate2D? {
        location.latestLocation?.coordinate
    }

    var activeRouteCoordinates: [CLLocationCoordinate2D] {
        if let route = currentRoute {
            return route.polylineCoordinates
        }
        return tripStore.session.activeRouteCoordinates.map(\.coordinate)
    }

    var isNightModeActive: Bool {
        mapThemeMode == .night
    }

    func onSceneActive() {
        location.requestWhenInUsePermission()
        location.startUpdating()
        startFollowCameraTimer()
        hydrateFromTripSession()
        search.setQueryFragment(searchText)
    }

    func onSceneInactive() {
        followCameraTimerCancellable?.cancel()
        followCameraTimerCancellable = nil
        routeRefreshDebounceTask?.cancel()
        routeRefreshDebounceTask = nil
        location.stopUpdating()
        geocoding.cancelPendingReverseGeocode()
    }

    func syncSearchQuery(_ text: String) {
        searchText = text
        search.setQueryFragment(text)
    }

    private func hydrateFromTripSession() {
        guard let d = tripStore.session.destination, let c = d.coordinate else { return }
        destination = PlaceResult(title: d.title, subtitle: d.subtitle, coordinate: c)
        mapMode = .browse
        showsSearchSuggestions = false
    }

    private func startFollowCameraTimer() {
        followCameraTimerCancellable?.cancel()
        followCameraTimerCancellable = Timer.publish(every: 0.35, tolerance: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.applyFollowModeCameraIfNeeded()
                self?.applyLiveRouteRefreshIfNeeded()
                self?.syncActiveTripProgressIfNeeded()
            }
    }

    func userDidManuallyAdjustCamera() {
        guard Date() > programmaticCameraSuppressUntil else { return }
        guard mapMode != .selectingDestination else { return }
        enterBrowseMode()
    }

    private func setProgrammaticCamera(_ position: MapCameraPosition) {
        programmaticCameraSuppressUntil = Date().addingTimeInterval(0.65)
        cameraPosition = position
    }

    func enterBrowseMode() {
        mapMode = .browse
    }

    func enterFollowUserMode() {
        mapMode = .followUser
        applyFollowModeCameraIfNeeded()
    }

    func centerOnUser() {
        enterFollowUserMode()
    }

    func toggleFollowUser() {
        if mapMode == .followUser {
            enterBrowseMode()
        } else {
            enterFollowUserMode()
        }
    }

    private func applyFollowModeCameraIfNeeded() {
        guard mapMode == .followUser else { return }
        guard let userCoord = location.latestLocation?.coordinate else { return }

        if let dest = displayDestinationCoordinate {
            if let region = Self.regionFitting(coordinates: [userCoord, dest], padding: 1.45) {
                setProgrammaticCamera(.region(region))
            }
        } else {
            let span = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
            setProgrammaticCamera(.region(MKCoordinateRegion(center: userCoord, span: span)))
        }
    }

    private func applyLiveRouteRefreshIfNeeded() {
        guard mapMode != .selectingDestination else { return }
        guard destination != nil else { return }

        // Refresh if we don't have a route yet (helps recover from early-origin failures),
        // or if we are actively following / viewing the route.
        let shouldAutoRefresh = (currentRoute == nil) || (mapMode == .followUser || mapMode == .viewingRoute)
        guard shouldAutoRefresh else { return }

        guard let currentLocation = location.latestLocation else { return }

        // Mimic SnoozeLane movement thresholds (location.speed in m/s).
        let speed = currentLocation.speed
        let minDistance: CLLocationDistance
        let minTime: TimeInterval
        if speed > 10 {
            minDistance = 50
            minTime = 30
        } else {
            minDistance = 30
            minTime = 60
        }

        if let lastOrigin = lastRouteOriginLocation, let lastBuiltAt = lastRouteBuildAt {
            if currentLocation.distance(from: lastOrigin) < minDistance { return }
            if Date().timeIntervalSince(lastBuiltAt) < minTime { return }
        }

        routeRefreshDebounceTask?.cancel()
        routeRefreshDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .milliseconds(1000))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            guard self.destination != nil else { return }
            guard self.mapMode != .selectingDestination else { return }
            guard let latestLocation = self.location.latestLocation else { return }

            let latestSpeed = latestLocation.speed
            let minDistance2: CLLocationDistance = latestSpeed > 10 ? 50 : 30
            let minTime2: TimeInterval = latestSpeed > 10 ? 30 : 60

            if let lastOrigin = self.lastRouteOriginLocation, let lastBuiltAt = self.lastRouteBuildAt {
                if latestLocation.distance(from: lastOrigin) < minDistance2 { return }
                if Date().timeIntervalSince(lastBuiltAt) < minTime2 { return }
            }

            // Mark the build time/location now so we suppress overlapping retries.
            self.lastRouteOriginLocation = latestLocation
            self.lastRouteBuildAt = Date()
            await self.buildRouteAsync()
        }
    }

    private func syncActiveTripProgressIfNeeded() {
        guard tripStore.session.status == .active else { return }
        guard let route = currentRoute else { return }
        guard let latestLocation = location.latestLocation else { return }
        // Straight-line distance so the wake trigger matches the alarm radius boundary,
        // not turn-by-turn road geometry.
        guard let destCoord = tripStore.session.destination?.coordinate ?? destination?.coordinate else { return }
        let destLocation = CLLocation(latitude: destCoord.latitude, longitude: destCoord.longitude)
        let straightDistanceMeters = latestLocation.distance(from: destLocation)

        tripStore.updateActiveProgress(
            distanceMeters: straightDistanceMeters,
            etaSeconds: route.expectedTravelTime,
            currentLocationLabel: "En route",
            routeCoordinates: route.polylineCoordinates
        )
        _ = tripStore.evaluateWakeTrigger()
    }

    func selectSearchCompletion(_ model: SearchCompletionModel) {
        showsSearchSuggestions = false
        Task { await resolveAndSetDestination(from: model) }
    }

    private func resolveAndSetDestination(from model: SearchCompletionModel) async {
        do {
            let place = try await search.resolveCompletion(model)
            let combinedLabel: String = {
                if place.subtitle.isEmpty { return place.title }
                return "\(place.title), \(place.subtitle)"
            }()
            await MainActor.run {
                setDestination(place)
                // Use a more descriptive label in the Home search bar.
                searchText = combinedLabel
            }
            await buildRouteAsync()
        } catch {
            await MainActor.run {
                routingErrorMessage = "Could not resolve that place. Try again."
            }
        }
    }

    func setDestination(_ place: PlaceResult) {
        destination = place
        dragPreviewCoordinate = nil
        syncTripStoreDestination(place)
        enterBrowseMode()
        Task { [weak self] in
            await self?.fetchLookAroundSceneForDestination()
        }
        if currentRoute != nil {
            Task { await buildRouteAsync() }
        } else {
            fitCameraToUserAndDestination()
        }
    }

    private func syncTripStoreDestination(_ place: PlaceResult) {
        tripStore.setDestination(
            CommuteDestination(
                title: place.title,
                subtitle: place.subtitle,
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude
            )
        )
    }

    func clearDestination() {
        routeGeneration += 1
        destination = nil
        dragPreviewCoordinate = nil
        currentRoute = nil
        routingErrorMessage = nil
        lastRouteOriginLocation = nil
        lastRouteBuildAt = nil
        routeRefreshDebounceTask?.cancel()
        routeRefreshDebounceTask = nil
        tripStore.clearDestination()
        lookAroundScene = nil
        isLookAroundLoading = false
        enterFollowUserMode()
    }

    func cycleMapDisplayType() {
        mapDisplayType = mapDisplayType.next()
        UserDefaults.standard.set(mapDisplayType.rawValue, forKey: PreferenceKey.mapDisplayType)
    }

    func toggleMapThemeMode() {
        mapThemeMode = mapThemeMode == .night ? .day : .night
        UserDefaults.standard.set(mapThemeMode.rawValue, forKey: PreferenceKey.mapTheme)
    }

    func commitLongPressDestination(at coordinate: CLLocationCoordinate2D) {
        routeGeneration += 1
        currentRoute = nil
        routeRefreshDebounceTask?.cancel()
        routeRefreshDebounceTask = nil
        geocoding.cancelPendingReverseGeocode()
        geocodeGeneration += 1
        let token = geocodeGeneration

        mapMode = .selectingDestination
        destination = PlaceResult(title: "Fetching address...", subtitle: "", coordinate: coordinate)
        dragPreviewCoordinate = nil
        lookAroundScene = nil
        isLookAroundLoading = true
        syncTripStoreDestination(destination ?? PlaceResult(title: "Fetching address...", subtitle: "", coordinate: coordinate))
        searchText = "Fetching address..."

        Task { [weak self] in
            guard let self else { return }
            var resolvedAddress = "Street address unavailable"
            do {
                resolvedAddress = try await geocoding.reverseGeocode(coordinate: coordinate)
            } catch {
                resolvedAddress = "Street address unavailable"
            }
            await MainActor.run {
                guard token == self.geocodeGeneration else { return }
                if var d = self.destination {
                    d.title = resolvedAddress
                    d.subtitle = ""
                    self.destination = d
                    self.syncTripStoreDestination(d)
                    self.searchText = resolvedAddress
                }
                self.mapMode = .browse
                self.fitCameraToUserAndDestination()
            }
            await self.buildRouteAsync()
            await self.fetchLookAroundSceneForDestination()
        }
    }

    func fetchLookAroundSceneForDestination() async {
        guard let destination else {
            lookAroundScene = nil
            isLookAroundLoading = false
            return
        }

        lookAroundGeneration += 1
        let token = lookAroundGeneration
        lookAroundScene = nil
        isLookAroundLoading = true

        let item = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        item.name = destination.title
        let request = MKLookAroundSceneRequest(mapItem: item)
        let scene = try? await request.scene
        guard token == lookAroundGeneration else { return }
        lookAroundScene = scene
        isLookAroundLoading = false
    }

    func clearRoute() {
        routeGeneration += 1
        currentRoute = nil
        routingErrorMessage = nil

        // Suppress immediate auto-refresh so "Clear route" does what the user expects.
        routeRefreshDebounceTask?.cancel()
        routeRefreshDebounceTask = nil
        lastRouteOriginLocation = location.latestLocation
        lastRouteBuildAt = Date()
    }

    func beginDraggingDestination() {
        routeGeneration += 1
        currentRoute = nil
        routeRefreshDebounceTask?.cancel()
        routeRefreshDebounceTask = nil
        geocoding.cancelPendingReverseGeocode()
        geocodeGeneration += 1
        mapMode = .selectingDestination
        dragPreviewCoordinate = destination?.coordinate
    }

    func updateDraggedDestination(_ coordinate: CLLocationCoordinate2D) {
        dragPreviewCoordinate = coordinate
    }

    func endDraggingDestination() {
        guard let coord = dragPreviewCoordinate else {
            mapMode = destination == nil ? .followUser : .browse
            dragPreviewCoordinate = nil
            return
        }
        let title = destination?.title ?? "Dropped pin"
        let subtitle = destination?.subtitle ?? ""
        destination = PlaceResult(title: title, subtitle: subtitle, coordinate: coord)
        dragPreviewCoordinate = nil
        mapMode = .browse

        geocodeGeneration += 1
        let token = geocodeGeneration
        Task { [weak self] in
            guard let self else { return }
            do {
                let subtitleResolved = try await geocoding.reverseGeocode(coordinate: coord)
                await MainActor.run {
                    guard token == self.geocodeGeneration else { return }
                    if var d = self.destination {
                        d.subtitle = subtitleResolved
                        self.destination = d
                        self.syncTripStoreDestination(d)
                    }
                }
                await self.buildRouteAsync()
            } catch {
                await MainActor.run {
                    guard token == self.geocodeGeneration else { return }
                    self.routingErrorMessage = "Could not look up address for that spot."
                }
            }
        }
    }

    func buildRoute() {
        Task { await buildRouteAsync() }
    }

    private func buildRouteAsync() async {
        routeGeneration += 1
        let token = routeGeneration
        guard let destCoord = destination?.coordinate else { return }
        guard let originCoord = location.latestLocation?.coordinate else {
            routingErrorMessage = "Waiting for your location to calculate a route."
            return
        }
        let transport = Self.transportType(for: tripStore.session.mode)
        do {
            let info = try await routing.route(from: originCoord, to: destCoord, transportType: transport)
            let straightPolyline = [originCoord, destCoord]
            await MainActor.run {
                guard token == self.routeGeneration else { return }
                // Draw polyline as a straight segment (no road geometry), but keep ETA/distance from MKDirections.
                let straightInfo = RouteInfo(route: info.route, polylineCoordinates: straightPolyline)
                self.currentRoute = straightInfo
                self.routingErrorMessage = nil
                self.mapMode = .viewingRoute
                self.applyRoutingToTripSession(straightInfo)
                self.tripStore.updateRouteCoordinates(straightInfo.polylineCoordinates)
                if let user = self.location.latestLocation?.coordinate {
                    self.tripStore.setOriginCoordinateIfNeeded(user)
                }
                self.syncActiveTripProgressIfNeeded()
                self.fitCameraToRoute(from: straightInfo)
            }
        } catch {
            await MainActor.run {
                guard token == self.routeGeneration else { return }
                self.routingErrorMessage = "Could not build a route."
                // Keep the last good route for resilience during transient failures.
            }
        }
    }

    private func applyRoutingToTripSession(_ info: RouteInfo) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let eta = Date().addingTimeInterval(info.expectedTravelTime)
        let etaString = formatter.string(from: eta)
        let distString: String
        switch UserSettingsStore.currentMeasurementUnit() {
        case .kilometers:
            distString = String(format: "%.1f km", info.distance / 1000)
        case .miles:
            distString = String(format: "%.1f mi", info.distance / 1609.344)
        }
        tripStore.applyRoutingSummary(etaDisplay: etaString, distanceDisplay: distString)
    }

    func fitCameraToRoute() {
        guard let r = currentRoute else { return }
        fitCameraToRoute(from: r)
    }

    private func fitCameraToRoute(from info: RouteInfo) {
        let coords = info.polylineCoordinates
        guard coords.count >= 2 else {
            // Fallback: if something weird happens, fit to user + destination.
            fitCameraToUserAndDestination()
            return
        }

        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        let rect = polyline.boundingMapRect
        let region = MKCoordinateRegion(rect)
        setProgrammaticCamera(.region(region))
    }

    func fitCameraToUserAndDestination() {
        guard let u = location.latestLocation?.coordinate, let d = displayDestinationCoordinate else { return }
        if let region = Self.regionFitting(coordinates: [u, d], padding: 1.45) {
            setProgrammaticCamera(.region(region))
        }
    }

    private static func regionFitting(coordinates: [CLLocationCoordinate2D], padding: Double) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        var minLat = coordinates[0].latitude
        var maxLat = minLat
        var minLon = coordinates[0].longitude
        var maxLon = minLon
        for c in coordinates {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        var latDelta = (maxLat - minLat) * padding
        var lonDelta = (maxLon - minLon) * padding
        latDelta = max(latDelta, 0.02)
        lonDelta = max(lonDelta, 0.02)
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        return MKCoordinateRegion(center: center, span: span)
    }

    private static func transportType(for mode: TransitMode) -> MKDirectionsTransportType {
        switch mode {
        case .car: .automobile
        case .train, .bus: .transit
        }
    }
}
