# Map feature architecture

SwiftUI-first navigation using **MapKit** (`Map`) and **Core Location**, with side effects in injectable services and state in `MapViewModel`.

## Layers

| Layer | Responsibility |
|-------|----------------|
| **Views** | `MapScreen`, `DraggableDestinationAnnotation`, `AdvancedMapViewRepresentable` (stub). No routing, geocoding, or completer logic. |
| **MapViewModel** | Camera mode (`MapMode`), destination, drag preview, search list mirror, route coordination, trip session sync. Throttles follow-mode camera; suppresses false user-pan detection after programmatic camera updates. |
| **Services** | `LocationService`, `SearchService`, `GeocodingService`, `RoutingService` — each behind a protocol for tests and future transit integrations. |
| **Models** | `PlaceResult`, `SearchCompletionModel`, `RouteInfo`, `MapPinModel`, `MapMode` in `MapModels.swift`. |

## Data flow

1. **Location** — `CLLocationManager` via `LocationService`. Start/stop tied to `MapScreen` visibility; follow framing on a short timer.
2. **Search** — `MKLocalSearchCompleter` debounced in `SearchService`; results pushed through `SearchCompletionPublishing`.
3. **Destination** — Completion resolves via `MKLocalSearch`. Drag updates coordinates only; reverse geocode and route on drag **end** (generation tokens drop stale work).
4. **Routing** — `MKDirections`. Car uses `.automobile`; train/bus use `.transit`. Success calls `TripSessionStore.applyRoutingSummary` for Home metrics.

## When to switch to `MKMapView` (UIKit bridge)

Stay on SwiftUI `Map` for simple annotations and polylines. Use `AdvancedMapViewRepresentable` when you need clustering, deep `MKMapViewDelegate` hooks, custom renderers, or gestures beyond `MapProxy` conversion.

## Device test checklist

- [ ] First launch: permission rationale; Allow → user dot and routes work.
- [ ] Deny location: search still works; inline message explains limits.
- [ ] Reduced/approximate accuracy: in-app notice is acceptable.
- [ ] Search → select → pin + route; **Plan wake** requires destination.
- [ ] Drag pin: no geocode/route spam during drag; updates after lift-off.
- [ ] Recenter / follow toggle; pan ends follow (after gesture ends).
- [ ] Change transit mode (car vs train/bus) and confirm route behavior where `.transit` exists.
- [ ] Leave and return to Home: no duplicate location churn.

## Simulator vs device

Routing/search need network; prefer a **physical device** for location accuracy and drag UX.
