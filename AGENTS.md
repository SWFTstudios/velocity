# AGENTS.md — Velocity

Instructions for contributors and AI assistants working on **Velocity**, a sleep app for commuters.

## Product summary

Users plan a **commute nap** by setting:

1. A **destination** (where they need to be alert).
2. A **wake radius** around that destination (wake when entering the zone, not only at a single coordinate).
3. A **mode of transportation**: **train**, **car**, or **bus**—used to reason about timing, variability, and how nap windows are estimated.

The app **estimates how long the user can safely nap** given route or schedule context and the selected mode. Users can review **sleep and transit history**. **Sleep quantity and quality** draw on:

- Information the user chooses to provide in-app, and  
- **HealthKit** and **third-party health apps**, only when the user has granted access.

Always design for **permission denial** and partial data: the app must remain usable when health or precise location is unavailable.

## Repository layout (target architecture)

The Xcode project uses a synchronized folder under `Velocity/`. As features grow, prefer grouping by **feature** plus shared **core** code (refactor when it pays off, not preemptively):

```text
Velocity/
  App/                    # App entry, composition root, environment setup
  Features/
    <FeatureName>/
      Views/
      ViewModels/
  Core/
    Models/
    Services/             # Location, notifications, HealthKit, persistence
    Utilities/
  DesignSystem/           # Shared styles, components (optional)
```

Keep **Apple framework boundaries** in services (Core Location, MapKit, User Notifications, HealthKit), not in SwiftUI views.

## SwiftUI and MVVM

| Layer | Responsibility |
|-------|----------------|
| **View** | Declares UI, reads view model state, forwards user actions. No direct I/O to HealthKit, location managers, or URL sessions. |
| **View model** | `@Observable`, usually `@MainActor`. Holds feature state, calls services, exposes loading/error states and user intents. |
| **Service / use case** | Side effects, async work, framework adapters. Small, testable surface; inject into view models. |

**State ownership:** The view model owns feature state; the view binds to it. Avoid duplicating the same source of truth in both.

**Previews:** Use lightweight mocks or preview-only view models so previews do not require device permissions or network.

**Navigation:** Prefer `NavigationStack` and typed routes or enums for multi-step commuter flows.

**Accessibility:** Support Dynamic Type, VoiceOver labels and hints, and reduce motion where animations are decorative. Do not rely on color alone for status (e.g. “wake soon”).

## Concurrency and Swift

- Prefer `async`/`await` and structured tasks; cancel work when views disappear or sessions end.
- When the project adopts **Swift 6** strict concurrency, align models and services with `Sendable` and explicit actor isolation to avoid data races.
- Run UI updates on the **main actor**; offload heavy work to detached tasks or nonisolated services and hop back to `@MainActor` for state updates.

## Data, privacy, and health

- **HealthKit:** Request read (and write, if ever needed) scopes that match features; explain in the privacy nutrition label and in-app copy *before* the system sheet.
- **Location:** Use clear rationale strings; support approximate location if product requirements allow.
- **Logging and analytics:** Do not log raw health samples, exact home/work coordinates, or free-form user medical notes.
- **Third-party health apps:** Integrate only through documented APIs (e.g. HealthKit as the aggregation layer on iOS where applicable).

## Testing

- **View models:** Primary unit-test target; inject protocols or structs that stand in for location, health, and time.
- **Swift Testing:** Prefer for new tests when the active Xcode version supports it in this repo.
- **XCTest:** Use when integrating with older tooling or when a specific API requires it.
- **Main actor:** Mark test types or methods `@MainActor` when testing `@MainActor` view models, or use supported isolation patterns for your Swift version.

## Run on a physical iPhone or iPad

The Xcode target uses **automatic signing** with a **development team** and bundle ID `com.swftstudios.Velocity` (see project settings). To install on your own device:

1. Open **`Velocity.xcodeproj`**, select the **Velocity** target → **Signing & Capabilities**.
2. Set **Team** to the Apple Developer team that should sign the app (the repo may list a team ID; change it if your Apple ID uses a different team).
3. Connect the device, pick it as the **run destination**, then **Run** (⌘R).
4. **iOS version:** the project’s **iPhone deployment target** must be **less than or equal to** the device’s iOS version. If install fails with an OS mismatch, either update the device or lower the deployment target in Xcode for the Velocity target.
5. On the device, enable **Settings → Privacy & Security → Developer Mode** if iOS prompts you (reboot if required).
6. After the first install, open **Settings → General → VPN & Device Management** and **trust** your developer certificate so the app can launch.

A **shared scheme** lives at [`Velocity.xcodeproj/xcshareddata/xcschemes/Velocity.xcscheme`](Velocity.xcodeproj/xcshareddata/xcschemes/Velocity.xcscheme) so the **Velocity** scheme is available without relying on user-specific scheme data.

## Cursor and MCP

- **Stitch MCP** is configured in [`.cursor/mcp.json`](.cursor/mcp.json) for editor/tooling use.
- Replace `YOUR-API-KEY` with a real key locally. **Do not commit production API keys.** Prefer placeholders in shared branches and team documentation that points to a secure secret store.

## Contributing

- Git branch and GitHub workflow: [CONTRIBUTING.md](CONTRIBUTING.md).

## What “done” looks like for a change

- Matches MVVM boundaries above.
- Respects privacy and permission states.
- Includes or updates tests when behavior is non-trivial.
- Previews still run without live credentials or device-only permissions.
