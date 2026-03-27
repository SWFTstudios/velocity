//
//  MapModels.swift
//  Velocity
//

import CoreLocation
import Foundation
import MapKit

struct PlaceResult: Identifiable, Sendable {
    let id: UUID
    var title: String
    var subtitle: String
    var coordinate: CLLocationCoordinate2D

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        coordinate: CLLocationCoordinate2D
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}

struct SearchCompletionModel: Identifiable, Equatable, Hashable, Sendable {
    var id: String { "\(title)|\(subtitle)" }
    var title: String
    var subtitle: String
}

struct RouteInfo: Identifiable, Sendable {
    let id: UUID
    let expectedTravelTime: TimeInterval
    let distance: CLLocationDistance
    let route: MKRoute
    let polylineCoordinates: [CLLocationCoordinate2D]

    /// Creates route info from an `MKRoute`.
    /// - Parameter polylineCoordinates: If provided, overrides the geometry used for drawing/camera fitting,
    ///   while still keeping `expectedTravelTime` and `distance` from the underlying `MKRoute`.
    init(route: MKRoute, polylineCoordinates: [CLLocationCoordinate2D]? = nil) {
        self.id = UUID()
        self.expectedTravelTime = route.expectedTravelTime
        self.distance = route.distance
        self.route = route
        self.polylineCoordinates = polylineCoordinates ?? route.polyline.coordinatesArray
    }
}

struct MapPinModel: Identifiable, Sendable {
    enum Kind: Equatable, Sendable {
        case user
        case destination
        case wakeZone
    }

    let id: UUID
    var title: String
    var coordinate: CLLocationCoordinate2D
    var kind: Kind
}

enum MapMode: Equatable, Sendable {
    case followUser
    case browse
    case selectingDestination
    case viewingRoute
}

enum MapDisplayType: String, CaseIterable, Sendable {
    case standard
    case hybrid
    case imagery

    var iconName: String {
        switch self {
        case .standard:
            return "map"
        case .hybrid:
            return "map.fill"
        case .imagery:
            return "globe.americas.fill"
        }
    }

    func next() -> MapDisplayType {
        switch self {
        case .standard:
            return .hybrid
        case .hybrid:
            return .imagery
        case .imagery:
            return .standard
        }
    }
}

enum MapThemeMode: String, Sendable {
    case day
    case night
}


extension PlaceResult: Equatable {
    static func == (lhs: PlaceResult, rhs: PlaceResult) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

extension MapPinModel: Equatable {
    static func == (lhs: MapPinModel, rhs: MapPinModel) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.kind == rhs.kind
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
