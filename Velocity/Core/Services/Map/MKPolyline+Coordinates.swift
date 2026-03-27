//
//  MKPolyline+Coordinates.swift
//  Velocity
//

import MapKit

extension MKPolyline {
    var coordinatesArray: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        if pointCount > 0 {
            getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        }
        return coords
    }
}
