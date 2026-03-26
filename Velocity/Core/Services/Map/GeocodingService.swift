//
//  GeocodingService.swift
//  Velocity
//
//  Reverse geocoding is cancelled when a new coordinate is committed so
//  dragging the pin does not stack many in-flight requests — only the final
//  position triggers a lookup (see MapViewModel.endDraggingDestination).
//

import CoreLocation
import Foundation

@MainActor
final class GeocodingService: NSObject, GeocodingProviding {
    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:]

    func cancelPendingReverseGeocode() {
        geocoder.cancelGeocode()
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        let key = Self.cacheKey(for: coordinate)
        if let cached = cache[key] { return cached }

        geocoder.cancelGeocode()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let pm = placemarks.first else {
            throw GeocodeError.noPlacemark
        }
        let formatted = Self.formatPlacemark(pm)
        cache[key] = formatted
        return formatted
    }

    enum GeocodeError: Error {
        case noPlacemark
    }

    private static func formatPlacemark(_ pm: CLPlacemark) -> String {
        if let thoroughfare = pm.thoroughfare, let locality = pm.locality {
            return "\(thoroughfare), \(locality)"
        }
        if let locality = pm.locality, let country = pm.country {
            return "\(locality), \(country)"
        }
        if let name = pm.name { return name }
        return "Selected location"
    }

    /// Coordinate-keyed cache key.
    /// We quantize to 4 decimals (~10m scale) to avoid repeated reverse-geocodes
    /// while still updating labels when the pin meaningfully moves.
    private static func cacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        let factor = 10000.0
        let lat = (coordinate.latitude * factor).rounded() / factor
        let lon = (coordinate.longitude * factor).rounded() / factor
        return "\(lat),\(lon)"
    }
}
