//
//  HomeTabRootView.swift
//  Velocity
//

import SwiftUI

struct HomeTabRootView: View {
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore
    @State private var path = NavigationPath()
    @State private var mapViewModel: MapViewModel
    @State private var showsLocationSearchModal = false
    @State private var mapFlowState: MapFlowState = .noInput

    private var tripSheetBinding: Binding<Bool> {
        Binding(
            get: {
                mapFlowState == .tripSetup || mapFlowState == .tripProgressShown
            },
            set: { presented in
                if !presented {
                    if tripStore.session.status == .planning {
                        mapFlowState = tripStore.session.destination == nil ? .noInput : .noInput
                    } else if tripStore.session.status != .idle {
                        mapFlowState = .tripProgressHidden
                    } else {
                        mapFlowState = .noInput
                    }
                }
            }
        )
    }

    private var showTripSetupReshowCTA: Bool {
        tripStore.session.destination != nil && tripStore.session.status == .planning && mapFlowState == .noInput
    }

    private var showTripProgressReshowCTA: Bool {
        tripStore.session.status != .idle
            && tripStore.session.status != .planning
            && mapFlowState == .tripProgressHidden
    }

    init(tripStore: TripSessionStore, settingsStore: UserSettingsStore) {
        self.tripStore = tripStore
        self.settingsStore = settingsStore
        _mapViewModel = State(initialValue: MapViewModel(tripStore: tripStore))
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeMapSearchView(
                tripStore: tripStore,
                settingsStore: settingsStore,
                mapViewModel: mapViewModel,
                onSearchTapped: {
                    showsLocationSearchModal = true
                    mapFlowState = .searching
                },
                showTripSetupReshowCTA: showTripSetupReshowCTA,
                onTripSetupReshowTapped: {
                    mapFlowState = .tripSetup
                    mapViewModel.beginTripSetupSheetPresentation()
                }
            )
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .activeTrip:
                        ActiveTripMapView(
                            tripStore: tripStore,
                            path: $path,
                            mapViewModel: mapViewModel,
                            showTripProgressReshowCTA: showTripProgressReshowCTA,
                            onTripProgressReshowTapped: {
                                mapFlowState = .tripProgressShown
                            }
                        )
                    case .wakeAlert:
                        WakeAlertView(tripStore: tripStore, path: $path)
                    }
                }
                .sheet(isPresented: $showsLocationSearchModal) {
                    LocationSearchView(
                        tripStore: tripStore,
                        settingsStore: settingsStore,
                        mapViewModel: mapViewModel,
                        onDismiss: { showsLocationSearchModal = false }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: tripSheetBinding) {
                    DynamicSheet(maxHeight: UIScreen.main.bounds.height * 0.5) {
                        if mapFlowState == .tripSetup || tripStore.session.status == .planning {
                            TripSetupFloatingSheetView(
                                tripStore: tripStore,
                                settingsStore: settingsStore,
                                mapViewModel: mapViewModel,
                                onDismiss: {
                                    mapViewModel.endTripSetupSheetPresentation()
                                    mapFlowState = .noInput
                                },
                                onConfirmTrip: {
                                    mapFlowState = .tripProgressShown
                                    path.append(HomeRoute.activeTrip)
                                }
                            )
                        } else {
                            TripProgressView(tripStore: tripStore) {
                                path = NavigationPath()
                            }
                        }
                    }
                    .presentationBackgroundInteraction(.enabled)
                    .presentationCornerRadius(22)
                    .onAppear {
                        // Only suppress search suggestions during trip setup on the Home map.
                        if tripStore.session.status == .planning {
                            mapViewModel.beginTripSetupSheetPresentation()
                        }
                    }
                    .onDisappear {
                        // Restore the captured map UI state when the entire trip sheet is dismissed.
                        mapViewModel.endTripSetupSheetPresentation()
                    }
                }
                .onChange(of: tripStore.session.destination) { _, newValue in
                    if newValue == nil {
                        mapFlowState = .noInput
                        return
                    }
                    // Selecting a destination always moves the app into trip setup.
                    if tripStore.session.status == .planning || tripStore.session.status == .idle {
                        mapFlowState = .tripSetup
                    }
                }
                .onChange(of: tripStore.session.status) { _, newStatus in
                    if newStatus == .idle {
                        mapFlowState = .noInput
                    } else if newStatus == .planning {
                        mapFlowState = .tripSetup
                    } else if newStatus == .active || newStatus == .waking || newStatus == .paused {
                        if mapFlowState != .tripProgressHidden {
                            mapFlowState = .tripProgressShown
                        }
                    }
                }
        }
    }
}

#Preview {
    HomeTabRootView(tripStore: TripSessionStore(), settingsStore: UserSettingsStore())
}
