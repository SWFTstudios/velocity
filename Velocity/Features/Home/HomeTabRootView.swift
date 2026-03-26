//
//  HomeTabRootView.swift
//  Velocity
//

import SwiftUI

struct HomeTabRootView: View {
    @Bindable var tripStore: TripSessionStore
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeMapSearchView(tripStore: tripStore, path: $path)
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .alarmSetup:
                        AlarmSetupView(tripStore: tripStore, path: $path)
                    case .activeTrip:
                        ActiveTripMapView(tripStore: tripStore, path: $path)
                    case .wakeAlert:
                        WakeAlertView(tripStore: tripStore, path: $path)
                    }
                }
        }
    }
}

#Preview {
    HomeTabRootView(tripStore: TripSessionStore())
}
