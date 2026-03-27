//
//  TripSessionStore.swift
//  Velocity
//

import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class TripSessionStore {
    var session: TripSession
    let historyStore: TripHistoryStore
    private let alarmCallService: AlarmCallService
    private let alarmRecipientNumber: String?

    init(
        session: TripSession? = nil,
        historyStore: TripHistoryStore? = nil,
        alarmCallService: AlarmCallService? = nil,
        alarmRecipientNumber: String? = nil
    ) {
        self.session = session ?? TripSession.empty()
        self.historyStore = historyStore ?? TripHistoryStore()
        self.alarmCallService = alarmCallService ?? NoopAlarmCallService()
        self.alarmRecipientNumber = alarmRecipientNumber
    }

    func setDestination(_ destination: CommuteDestination) {
        let previousDestination = session.destination
        session.destination = destination
        session.status = .planning
        session.nextStopName = destination.title

        // Apply the user's default wake radius when a new destination is selected.
        let isNewSelection: Bool = {
            guard let prev = previousDestination else { return true }
            if let prevLat = prev.latitude, let prevLon = prev.longitude {
                return prevLat != destination.latitude || prevLon != destination.longitude
            }
            return true
        }()

        if isNewSelection {
            session.threshold = .distanceKilometers(UserSettingsStore.currentDefaultWakeRadiusKilometers())
            session.wakeRadiusBadgeText = session.wakeBadgeText()
        }

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
        session.onTrackLabel = "ON TRACK"
        session.currentLocationLabel = "En route"
        session.startedAt = Date()
        session.endedAt = nil
        session.wakeTriggeredAt = nil
        session.wakeTriggerReason = nil
        session.activeDistanceMeters = nil
        session.activeETASeconds = nil
        session.alarmCallState = .idle
        session.lastAlarmCallErrorMessage = nil
        session.lastAlarmCallAt = nil
        session.alarmCallIdempotencyKey = nil
        session.alarmCallSid = nil
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
        completeTrip(wasAwakened: false)
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

    func updateRouteCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        session.activeRouteCoordinates = coordinates.map(CoordinatePoint.init)
    }

    func setOriginCoordinateIfNeeded(_ coordinate: CLLocationCoordinate2D) {
        guard session.originCoordinate == nil else { return }
        session.originCoordinate = CoordinatePoint(coordinate)
    }

    func updateActiveProgress(
        distanceMeters: CLLocationDistance,
        etaSeconds: TimeInterval,
        currentLocationLabel: String,
        routeCoordinates: [CLLocationCoordinate2D]
    ) {
        guard session.status == .active || session.status == .paused else { return }
        session.activeDistanceMeters = distanceMeters
        session.activeETASeconds = etaSeconds
        session.currentLocationLabel = currentLocationLabel
        session.minutesToDestination = max(Int((etaSeconds / 60).rounded()), 0)
        session.distanceDisplay = formatDistance(distanceMeters)
        session.etaDisplay = etaClockDisplay(from: etaSeconds)
        session.activeRouteCoordinates = routeCoordinates.map(CoordinatePoint.init)
    }

    @discardableResult
    func evaluateWakeTrigger() -> Bool {
        guard session.status == .active else { return false }
        guard session.destination != nil else { return false }
        guard session.wakeTriggeredAt == nil else { return false }

        switch session.threshold {
        case let .distanceKilometers(km):
            guard let distance = session.activeDistanceMeters else { return false }
            if distance <= (km * 1000) {
                triggerWake(reason: .distanceThreshold)
                return true
            }
        case let .timeBeforeArrival(seconds):
            guard let eta = session.activeETASeconds else { return false }
            if eta <= seconds {
                triggerWake(reason: .timeThreshold)
                return true
            }
        }
        return false
    }

    func triggerWake(reason: WakeTriggerReason) {
        guard session.status == .active || session.status == .paused else { return }
        session.status = .waking
        session.onTrackLabel = "WAKE ALERT"
        session.wakeTriggeredAt = Date()
        session.wakeTriggerReason = reason
        if session.alarmCallIdempotencyKey == nil {
            session.alarmCallIdempotencyKey = UUID().uuidString
        }
        Task {
            await triggerAlarmCallIfNeeded()
        }
    }

    func retryAlarmCall() async {
        guard session.status == .waking else { return }
        await triggerAlarmCall(forceRetry: true)
    }

    private func triggerAlarmCallIfNeeded() async {
        guard session.status == .waking else { return }
        if session.alarmCallState == .calling || session.alarmCallState == .success {
            return
        }
        await triggerAlarmCall(forceRetry: false)
    }

    private func triggerAlarmCall(forceRetry: Bool) async {
        guard let wakeReason = session.wakeTriggerReason else { return }
        guard let to = alarmRecipientNumber, !to.isEmpty else {
            session.alarmCallState = .skippedNotConfigured
            session.lastAlarmCallErrorMessage = "Call service not configured."
            return
        }
        if !forceRetry, session.lastAlarmCallAt != nil, session.alarmCallState == .failed {
            return
        }

        let idempotencyKey = session.alarmCallIdempotencyKey ?? UUID().uuidString
        session.alarmCallIdempotencyKey = idempotencyKey
        session.alarmCallState = .calling
        session.lastAlarmCallErrorMessage = nil

        let request = AlarmCallRequest(
            tripId: session.id.uuidString,
            to: to,
            wakeReason: mapWakeReason(wakeReason),
            idempotencyKey: idempotencyKey,
            message: "Velocity wake-up call.",
            destinationTitle: session.destination?.title,
            destinationSubtitle: session.destination?.subtitle,
            etaDisplay: session.etaDisplay,
            distanceDisplay: session.distanceDisplay,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        let result: AlarmCallResult
        do {
            result = try await alarmCallService.triggerAlarmCall(request)
        } catch {
            result = AlarmCallResult(status: .failed, callSid: nil, userFacingMessage: "Unable to place wake call.")
        }

        session.lastAlarmCallAt = Date()
        session.alarmCallSid = result.callSid
        switch result.status {
        case .success, .duplicate:
            session.alarmCallState = .success
            session.lastAlarmCallErrorMessage = nil
        case .failed:
            session.alarmCallState = .failed
            session.lastAlarmCallErrorMessage = result.userFacingMessage
            print("Alarm call attempt failed for trip \(session.id.uuidString)")
        }
    }

    func completeTrip(wasAwakened: Bool) {
        guard let destination = session.destination else {
            session = TripSession.empty(id: UUID())
            return
        }
        let endedAt = Date()
        let startedAt = session.startedAt ?? endedAt
        let record = TripRecord(
            id: session.id,
            startedAt: startedAt,
            endedAt: endedAt,
            mode: session.mode,
            threshold: session.threshold,
            destination: destination,
            originCoordinate: session.originCoordinate,
            finalDistanceMeters: session.activeDistanceMeters,
            finalETASeconds: session.activeETASeconds,
            wakeTriggeredAt: session.wakeTriggeredAt,
            wakeTriggerReason: session.wakeTriggerReason,
            wasAwakened: wasAwakened,
            routeCoordinates: session.activeRouteCoordinates,
            alarmCallState: session.alarmCallState,
            alarmCallSid: session.alarmCallSid,
            alarmCallErrorMessage: session.lastAlarmCallErrorMessage
        )
        historyStore.append(record)
        session = TripSession.empty(id: UUID())
    }

    private func mapWakeReason(_ reason: WakeTriggerReason) -> AlarmWakeReason {
        switch reason {
        case .distanceThreshold:
            return .distanceThreshold
        case .timeThreshold:
            return .timeThreshold
        case .manual:
            return .manual
        }
    }

    private func etaClockDisplay(from etaSeconds: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: Date().addingTimeInterval(max(etaSeconds, 0)))
    }

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        switch UserSettingsStore.currentMeasurementUnit() {
        case .kilometers:
            return String(format: "%.1f km", meters / 1000)
        case .miles:
            return String(format: "%.1f mi", meters / 1609.344)
        }
    }
}

