//
//  LocationService.swift
//  Velocity
//
//  Wraps CLLocationManager. Updates are delivered on the main actor.
//  Reduced accuracy is surfaced via accuracyAuthorization so UI can explain
//  limitations without spamming system prompts.
//

import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var latestLocation: CLLocation?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    var accuracyAuthorization: CLAccuracyAuthorization {
        manager.accuracyAuthorization
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }

    func requestWhenInUsePermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestSingleLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.singleContinuation = continuation
            manager.requestLocation()
        }
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    private var singleContinuation: CheckedContinuation<CLLocation, Error>?

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.latestLocation = loc
            if let c = self.singleContinuation {
                self.singleContinuation = nil
                c.resume(returning: loc)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let c = self.singleContinuation {
                self.singleContinuation = nil
                c.resume(throwing: error)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        _ = manager.authorizationStatus
    }
}
