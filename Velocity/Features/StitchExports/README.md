# Stitch exports

This folder holds **imports from Google Stitch** for the Velocity commuter-sleep UI.

## Contents

- `manifest.json` — project metadata and hosted URLs used for download (regenerate via Stitch MCP if screens change).
- `download.sh` — `curl -L` commands for the last export (regenerated with manifest).
- `Raw/` — Stitch **HTML** exports (`*.html`) and the **design system** markdown (`DesignSystem.md`).
- `Views/` — SwiftUI **wrapper views** that display catalog screenshots and point to raw HTML. Stitch does not emit SwiftUI for these screens; translate HTML into native SwiftUI in feature modules when you implement flows.

## Assets

Screen screenshots live in `Assets.xcassets/StitchScreens/` as `*.imageset` entries (e.g. `Image("HomeMapSearch")`).

## Refreshing exports

1. Call Stitch MCP `get_screen` / `list_design_systems` with your API key.
2. Update `manifest.json` and re-run `download.sh` (or equivalent `curl -L` commands) on a machine with network access.
