//
//  AdvancedMapViewRepresentable.swift
//  Velocity
//
//  Future upgrade path when SwiftUI Map is insufficient (clustering, custom
//  MKMapViewDelegate hooks, complex overlays, or advanced edit gestures).
//  Not wired into production screens yet.
//

import MapKit
import SwiftUI

struct AdvancedMapViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.mapType = .mutedStandard
        map.pointOfInterestFilter = .excludingAll
        map.isRotateEnabled = false
        map.showsUserLocation = true
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Intentionally empty — bind camera, annotations, and overlays here when adopted.
    }

    final class Coordinator: NSObject {
        var parent: AdvancedMapViewRepresentable
        init(parent: AdvancedMapViewRepresentable) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
