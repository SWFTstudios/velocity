//
//  TripSessionStore.swift
//  Velocity
//

import Foundation
import Observation

@Observable
@MainActor
final class TripSessionStore {
    var session: TripSession

    init(session: TripSession? = nil) {
        self.session = session ?? TripSession.empty()
    }

    func setDestination(_ destination: CommuteDestination) {
        session.destination = destination
        session.status = .planning
        session.nextStopName = destination.title
        session.applySamplePlanningData()
        session.napEstimateMinutes = Self.stubNapEstimateMinutes(for: session.mode)
    }

    func clearDestination() {
        session = TripSession.empty(id: session.id)
    }

    func setThreshold(_ threshold: WakeThreshold) {
        session.threshold = threshold
        session.wakeRadiusBadgeText = session.wakeBadgeText()
    }

    func setTransitMode(_ mode: TransitMode) {
        session.mode = mode
        session.napEstimateMinutes = Self.stubNapEstimateMinutes(for: mode)
    }

    /// Stub until `NapEstimateService` exists.
    private static func stubNapEstimateMinutes(for mode: TransitMode) -> Int {
        switch mode {
        case .train: 42
        case .car: 28
        case .bus: 35
        }
    }

    func startTrip() {
        guard session.destination != nil else { return }
        session.status = .active
        session.etaDisplay = "06:45 AM"
        session.distanceDisplay = "12.4 km"
        session.onTrackLabel = "ON TRACK"
        session.currentLocationLabel = "En route"
        session.minutesToDestination = 12
    }

    func pauseTrip() {
        guard session.status == .active else { return }
        session.status = .paused
        session.onTrackLabel = "PAUSED"
    }

    func resumeTrip() {
        guard session.status == .paused else { return }
        session.status = .active
        session.onTrackLabel = "ON TRACK"
    }

    func endTrip() {
        session = TripSession.empty(id: UUID())
    }

    func applyWakePreview(minutes: Int = 4) {
        session.minutesToDestination = minutes
        session.currentLocationLabel = "Grand Central District"
        session.etaDisplay = "06:42 AM"
    }

    /// Updates ETA / distance from live MapKit routing.
    func applyRoutingSummary(etaDisplay: String, distanceDisplay: String) {
        session.etaDisplay = etaDisplay
        session.distanceDisplay = distanceDisplay
    }
}

