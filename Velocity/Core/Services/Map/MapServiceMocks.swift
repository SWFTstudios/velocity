//
//  MapServiceMocks.swift
//  Velocity
//
//  Preview and unit-test doubles. No live location or MapKit queries.
//

#if DEBUG
import CoreLocation
import Foundation
import MapKit

@MainActor
final class MockLocationService: LocationProviding {
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
    var latestLocation: CLLocation?

    init(
        coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
    ) {
        latestLocation = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date())
    }

    func requestWhenInUsePermission() {}

    func requestSingleLocation() async throws -> CLLocation {
        guard let latestLocation else {
            throw NSError(domain: "MockLocation", code: 0)
        }
        return latestLocation
    }

    func startUpdating() {}
    func stopUpdating() {}
}

@MainActor
final class MockSearchService: SearchProviding, SearchCompletionPublishing {
    private(set) var completions: [SearchCompletionModel] = [
        SearchCompletionModel(title: "St Pancras", subtitle: "London, UK"),
        SearchCompletionModel(title: "King's Cross", subtitle: "London, UK")
    ]

    var onCompletionsUpdated: (() -> Void)?

    func setQueryFragment(_ fragment: String) {
        onCompletionsUpdated?()
    }

    func resolveCompletion(_ model: SearchCompletionModel) async throws -> PlaceResult {
        PlaceResult(
            title: model.title,
            subtitle: model.subtitle,
            coordinate: CLLocationCoordinate2D(latitude: 51.5319, longitude: -0.1263)
        )
    }
}

@MainActor
final class MockGeocodingService: GeocodingProviding {
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        "London, United Kingdom"
    }

    func cancelPendingReverseGeocode() {}
}

@MainActor
final class MockRoutingService: RoutingProviding {
    func route(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType
    ) async throws -> RouteInfo {
        throw NSError(domain: "MockRouting", code: 0, userInfo: [NSLocalizedDescriptionKey: "Use live RoutingService on device"])
    }
}
#endif
