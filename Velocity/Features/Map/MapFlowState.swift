//
//  MapFlowState.swift
//  Velocity
//

import Foundation

/// SnoozeLane-style UI state for how the map/search/trip setup flow is currently presented.
/// This is separate from `MapMode` (camera behavior) and from `TripStatus` (trip lifecycle).
enum MapFlowState: Equatable {
    case noInput
    case searching
    case tripSetup
    case tripProgressShown
    case tripProgressHidden
}

