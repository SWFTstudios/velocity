//
//  RoutingService.swift
//  Velocity
//
//  Uses MKDirections. Additional routes or transit-specific requests can be
//  added by extending this type or injecting a different RoutingProviding.
//

import CoreLocation
import Foundation
import MapKit

@MainActor
final class RoutingService: RoutingProviding {
    private var currentDirections: MKDirections?

    func route(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType
    ) async throws -> RouteInfo {
        currentDirections?.cancel()
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = transportType
        let directions = MKDirections(request: request)
        currentDirections = directions
        let response = try await directions.calculate()
        guard let first = response.routes.first else {
            throw RoutingError.noRoutes
        }
        return RouteInfo(route: first)
    }

    enum RoutingError: Error {
        case noRoutes
    }
}
