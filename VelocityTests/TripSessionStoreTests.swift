import CoreLocation
import XCTest
@testable import Velocity

@MainActor
final class TripSessionStoreTests: XCTestCase {
    func testDistanceThresholdTriggersWake() {
        let history = TripHistoryStore()
        let store = TripSessionStore(historyStore: history)
        store.setDestination(
            CommuteDestination(
                title: "St Pancras",
                subtitle: "London",
                latitude: 51.5319,
                longitude: -0.1263
            )
        )
        store.setThreshold(.distanceKilometers(1.0))
        store.startTrip()

        store.updateActiveProgress(
            distanceMeters: 800,
            etaSeconds: 600,
            currentLocationLabel: "Approaching",
            routeCoordinates: []
        )

        XCTAssertTrue(store.evaluateWakeTrigger())
        XCTAssertEqual(store.session.status, .waking)
        XCTAssertEqual(store.session.wakeTriggerReason, .distanceThreshold)
    }

    func testCompletingTripPersistsRecord() {
        let history = TripHistoryStore()
        history.clearAll()

        let store = TripSessionStore(historyStore: history)
        store.setDestination(
            CommuteDestination(
                title: "Airport",
                subtitle: "San Jose",
                latitude: 37.3639,
                longitude: -121.9289
            )
        )
        store.startTrip()
        store.updateActiveProgress(
            distanceMeters: 1200,
            etaSeconds: 420,
            currentLocationLabel: "En route",
            routeCoordinates: [CLLocationCoordinate2D(latitude: 37.3, longitude: -121.9)]
        )
        store.completeTrip(wasAwakened: true)

        XCTAssertEqual(history.records.count, 1)
        XCTAssertTrue(history.records[0].wasAwakened)
        XCTAssertEqual(history.records[0].destination.title, "Airport")
    }

    func testWakeTriggerInitiatesAlarmCallAndSetsSuccessState() async {
        let history = TripHistoryStore()
        let mockService = CountingAlarmCallService(result: AlarmCallResult(status: .success, callSid: "CA_123", userFacingMessage: "ok"))
        let store = TripSessionStore(
            historyStore: history,
            alarmCallService: mockService,
            alarmRecipientNumber: "+15555550123"
        )
        store.setDestination(
            CommuteDestination(
                title: "Union Station",
                subtitle: "Los Angeles",
                latitude: 34.0562,
                longitude: -118.2365
            )
        )
        store.startTrip()

        store.triggerWake(reason: .manual)
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(store.session.alarmCallState, .success)
        XCTAssertEqual(store.session.alarmCallSid, "CA_123")
        XCTAssertEqual(mockService.callCount, 1)
    }

    func testRetryAlarmCallTransitionsFailedToSuccess() async {
        let history = TripHistoryStore()
        let mockService = SequenceAlarmCallService(results: [
            AlarmCallResult(status: .failed, callSid: nil, userFacingMessage: "first failed"),
            AlarmCallResult(status: .success, callSid: "CA_456", userFacingMessage: "second ok")
        ])
        let store = TripSessionStore(
            historyStore: history,
            alarmCallService: mockService,
            alarmRecipientNumber: "+15555550123"
        )
        store.setDestination(
            CommuteDestination(
                title: "Downtown",
                subtitle: "San Francisco",
                latitude: 37.7749,
                longitude: -122.4194
            )
        )
        store.startTrip()

        store.triggerWake(reason: .manual)
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(store.session.alarmCallState, .failed)

        await store.retryAlarmCall()
        XCTAssertEqual(store.session.alarmCallState, .success)
        XCTAssertEqual(mockService.callCount, 2)
    }
}

@MainActor
private final class CountingAlarmCallService: AlarmCallService {
    var callCount = 0
    let result: AlarmCallResult

    init(result: AlarmCallResult) {
        self.result = result
    }

    func triggerAlarmCall(_ request: AlarmCallRequest) async throws -> AlarmCallResult {
        callCount += 1
        return result
    }
}

@MainActor
private final class SequenceAlarmCallService: AlarmCallService {
    var callCount = 0
    private var results: [AlarmCallResult]

    init(results: [AlarmCallResult]) {
        self.results = results
    }

    func triggerAlarmCall(_ request: AlarmCallRequest) async throws -> AlarmCallResult {
        callCount += 1
        if results.isEmpty {
            return AlarmCallResult(status: .failed, callSid: nil, userFacingMessage: "no result")
        }
        return results.removeFirst()
    }
}

