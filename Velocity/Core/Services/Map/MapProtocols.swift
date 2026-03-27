//
//  MapProtocols.swift
//  Velocity
//
//  Protocol abstractions for testability and future transit integrations.
//

import CoreLocation
import Foundation
import MapKit

protocol LocationProviding: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var accuracyAuthorization: CLAccuracyAuthorization { get }
    var latestLocation: CLLocation? { get }
    func requestWhenInUsePermission()
    func requestSingleLocation() async throws -> CLLocation
    func startUpdating()
    func stopUpdating()
}

protocol SearchProviding: AnyObject {
    var completions: [SearchCompletionModel] { get }
    /// Debounced inside the implementation — safe to call on each keystroke.
    func setQueryFragment(_ fragment: String)
    func resolveCompletion(_ model: SearchCompletionModel) async throws -> PlaceResult
}

protocol GeocodingProviding: AnyObject {
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String
    func cancelPendingReverseGeocode()
}

protocol RoutingProviding: AnyObject {
    func route(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType
    ) async throws -> RouteInfo
}

/// Optional hook so `MapViewModel` can mirror completer results without polling.
@MainActor
protocol SearchCompletionPublishing: AnyObject, SearchProviding {
    var onCompletionsUpdated: (() -> Void)? { get set }
}
