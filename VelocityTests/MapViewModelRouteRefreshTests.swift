import CoreLocation
import MapKit
import XCTest
@testable import Velocity

@MainActor
final class MapViewModelRouteRefreshTests: XCTestCase {
    func testBuildRouteFailureSetsErrorMessage() async {
        let store = TripSessionStore(historyStore: TripHistoryStore())
        let services = MapServices(
            location: MockLocationService(
                coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
            ),
            search: MockSearchService(),
            geocoding: MockGeocodingService(),
            routing: FailingRoutingService()
        )

        let vm = MapViewModel(tripStore: store, services: services)
        vm.setDestination(
            PlaceResult(
                title: "Destination",
                subtitle: "Sample",
                coordinate: CLLocationCoordinate2D(latitude: 37.3639, longitude: -121.9289)
            )
        )

        vm.buildRoute()
        // Allow async route task to complete.
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertNil(vm.currentRoute)
        XCTAssertEqual(vm.routingErrorMessage, "Could not build a route.")
    }
}

@MainActor
private final class FailingRoutingService: RoutingProviding {
    func route(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType
    ) async throws -> RouteInfo {
        throw NSError(domain: "FailingRoutingService", code: 1)
    }
}

