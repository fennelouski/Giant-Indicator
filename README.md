# Giant Indicator

Giant Indicator is a SwiftUI app for iPhone, iPad, and macOS that shows large, glanceable device status indicators from across the room.

The app is designed to make key system state immediately readable at a distance, including battery percentage, media playback and metadata, volume level, time/date, and connectivity/system toggles (Wi-Fi, Wi-Fi strength, speaker, Bluetooth, ringer/silent).

## Why This App Exists

Many system details are available in Control Center or status bars, but they are too small to read from far away. Giant Indicator solves this by rendering selected signals as oversized, high-contrast visual tiles on an adaptable background.

## Core Experience

1. Open the app.
2. Tap the small gear icon in the corner.
3. Select which indicators to display.
4. Close settings and leave the screen on.
5. Read the status from across the room.

## Planned Features

- Oversized battery tile with percentage-first readability and optional fill visualization
- Large volume level indicator
- Large media playback state indicator (playing/paused/idle)
- Currently playing media metadata (track, artist, optional album)
- Large status indicators for Wi-Fi, Wi-Fi signal strength, speaker output, Bluetooth, and ringer/silent
- Configurable background mode (System/Light/Dark)
- Optional battery-reactive background brightness (black at <10% to white at 100%)
- Optional battery-driven screen brightness rule: `max((batteryLevel^2), 0.10)` where `batteryLevel` is normalized 0.0-1.0
- Status bar show/hide setting (default hidden on supported platforms)
- Large time tile with optional seconds display
- Large date tile
- Non-scrolling masonry-style layout that adapts to the active indicators
- Resizable layout behavior for iPad multitasking and macOS windows
- Per-user indicator visibility preferences via in-app settings

## Platform Targets

- iPhone (primary)
- iPad (resizable layouts and split-view compatibility)
- macOS (window-resizable utility use case)

## Design Principles

- At-a-distance readability first
- Minimal interaction after setup
- High contrast and visual clarity
- Extremely low overhead rendering and update costs
- Stable, responsive layout under dynamic resizing

## Technical Direction

- **UI framework:** SwiftUI
- **Layout strategy:** masonry-inspired adaptive grid without scrolling
- **Performance goals:** low CPU/GPU usage while idle and during updates
- **State model:** preference-driven tile composition and lightweight status polling/subscriptions
- **Battery UX behavior:** percentage-first communication, optional battery-reactive background, optional quadratic brightness mapping with 10% floor
- **Clock/date behavior:** real-time updates with optional seconds precision

## Repository Structure

- `Giant Indicator/` - app source
- `Giant IndicatorTests/` - unit tests
- `Giant IndicatorUITests/` - UI tests
- `docs/` - product and project documentation

## Documentation

- Product Requirements Document: `docs/PRD.md`

## Status

Project is in early definition/implementation phase. See `docs/PRD.md` for complete requirements and acceptance criteria.
