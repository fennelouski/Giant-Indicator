# Product Requirements Document (PRD)

## 1) Product Overview

### 1.1 Product Name
Giant Indicator

### 1.2 Problem Statement
Users cannot easily read important device status information (battery, volume, playback, connectivity, ringer state) from across a room because existing system UI is too small or hidden behind interaction layers.

### 1.3 Product Vision
Create a simple, always-on, high-visibility dashboard that shows selected device status indicators in oversized, readable tiles with minimal power and CPU usage.

### 1.4 Target Platforms
- iPhone
- iPad
- macOS

## 2) Goals and Non-Goals

### 2.1 Goals
- Make selected status information readable from across the room.
- Allow users to choose which indicators are shown.
- Fit all selected indicators in a non-scrolling adaptive masonry layout.
- Support dynamic resizing on iPad and macOS.
- Keep runtime overhead low for long-duration display use.

### 2.2 Non-Goals (Phase 1)
- Historical charts or long-term analytics.
- Remote monitoring from another device.
- Complex theming or advanced visual customization beyond visibility toggles and basic sizing behavior.
- Rich media controls (skip/seek) as a primary interaction model.

## 3) Target Users and Use Cases

### 3.1 Primary Users
- Users charging a device across the room.
- Users who need quick playback/volume confirmation from a distance.
- Users who need quick connectivity/ringer state checks without approaching device.

### 3.2 Core Use Cases
- View battery level at a distance while charging.
- Verify current volume level at a glance.
- Check playback state (playing/paused/stopped).
- Confirm Wi-Fi, speaker output, Bluetooth, and ringer/silent statuses.
- Configure visible indicators once, then leave app open.

## 4) Product Requirements (Numbered)

### PR-1 App Launch and Main Screen
The app shall open directly to a full-screen (or window-filling) dashboard with a black background and visible indicators.

### PR-2 Settings Access
The app shall provide a small gear icon in a corner of the dashboard to open settings.

### PR-3 Indicator Visibility Controls
The settings screen shall allow users to independently enable/disable each supported indicator.

### PR-4 Persisted Preferences
The app shall persist indicator visibility preferences across app launches.

### PR-5 Battery Indicator
The app shall support a large battery tile that:
1. Displays current battery percentage.
2. Uses an oversized battery icon shape.
3. Fills/shades the battery interior proportionally to battery level.
4. Is readable from across the room.

### PR-6 Volume Indicator
The app shall support a large volume tile that visually represents current output volume level.

### PR-7 Playback State Indicator
The app shall support a large media playback state tile that clearly differentiates playing, paused, and idle/stopped states.

### PR-8 Connectivity/Status Indicators
The app shall support large tiles/icons for:
1. Wi-Fi status
2. Speaker/output status
3. Bluetooth status
4. Ringer/silent status (platform-permitted)

### PR-9 Masonry Layout Without Scrolling
The app shall place all enabled indicators in a non-scrolling masonry-style layout that uses available screen/window space efficiently.

### PR-10 Adaptive Layout Rules
The layout engine shall:
1. Prioritize large readable tiles.
2. Reflow dynamically when indicators are enabled/disabled.
3. Reflow dynamically on orientation/size changes.
4. Keep all enabled indicators visible without requiring scrolling.

### PR-11 iPad and macOS Resizability
The app shall support smooth, responsive resizing in iPad multitasking and macOS window resizing while preserving readability and non-scrolling behavior.

### PR-12 Performance Constraints
The app shall be optimized for low resource usage by:
1. Avoiding expensive redraws when data is unchanged.
2. Using efficient update intervals/subscriptions.
3. Maintaining low CPU usage during steady-state display.

### PR-13 Visual Accessibility and Readability
The app shall use high-contrast visuals and large iconography/text sizing suitable for at-a-distance reading.

### PR-14 Keep-Screen-On Behavior
The app shall provide an option (or default behavior where permitted) to keep the display active while the dashboard is in use.

### PR-15 Platform Capability Handling
The app shall gracefully handle platform-level limitations (for example, unavailable APIs on specific OS versions or platforms) by:
1. Hiding unsupported indicators, or
2. Showing a clear unavailable state.

### PR-16 Robust Error/Unavailable States
Each indicator shall define a clear fallback visual for unavailable, permission-limited, or unknown data states.

### PR-17 Battery Percentage-First Rendering
The app shall support a battery display mode that communicates battery level using numeric percentage prominence rather than color dependence, so level remains clear in monochrome/high-contrast viewing conditions.

### PR-18 Currently Playing Metadata
The app shall support a "Now Playing" tile that displays currently playing media metadata, including:
1. Track title
2. Artist name
3. Optional album name when available
4. Clear fallback state when no media is active

### PR-19 Wi-Fi Signal Strength Indicator
The app shall support a Wi-Fi tile that includes signal strength representation (for example, bars/percentage) in addition to Wi-Fi enabled/disabled state.

### PR-20 Theme-Aware Background Mode
The app shall support Light Mode and Dark Mode background behavior, with user-selectable preference (system/light/dark) where platform conventions permit.

### PR-21 Battery-Reflective Background Intensity
The app shall support an optional battery-reactive background mode where background brightness maps to battery level from black at <10% to white at 100%, with smooth interpolation between bounds.

### PR-22 Battery-Driven Screen Brightness Control
Where platform APIs permit, the app shall support optional automatic screen brightness control based on battery level using:
1. `brightness = max((batteryLevelNormalized ^ 2), 0.10)`
2. `batteryLevelNormalized = batteryPercentage / 100`
3. Example: 20% -> `max(0.2^2, 0.10)` -> 10%
4. Example: 40% -> `max(0.4^2, 0.10)` -> 16%
5. Example: 80% -> `max(0.8^2, 0.10)` -> 64%
6. If platform control is unavailable (for example on some macOS contexts), the app shall present a clear unavailable/disabled state.

### PR-23 Status Bar Visibility Control
The app shall provide a user setting to show/hide the status bar on supported platforms, with default set to hidden.

### PR-24 Clock Display
The app shall support a large, at-a-distance readable time tile.

### PR-25 Clock Seconds Option
The app shall provide a setting to show time with seconds when the time tile is enabled.

### PR-26 Date Display
The app shall support a large, readable date tile, independently toggleable from time display.

## 5) Functional Specification Details

### 5.1 Supported Indicator Set (Phase 1)
- Battery
- Volume
- Playback state
- Now Playing metadata
- Wi-Fi
- Wi-Fi signal strength
- Speaker/output route
- Bluetooth
- Ringer/silent (where technically available)
- Time
- Time with seconds (optional format mode)
- Date

### 5.2 Configuration Model
- Toggle list in settings for each indicator.
- Optional tile priority ordering reserved for future phase.

### 5.3 Update Strategy
- Real-time or near-real-time updates when system signals change.
- Debounced or event-driven redraw strategy to reduce unnecessary work.

## 6) UX Requirements

- Default screen should be immediately useful without onboarding.
- Settings must be quick to open/close and minimally intrusive.
- Icons and state changes should be unambiguous at distance.
- Black background should remain dominant to reduce visual noise and power draw.

## 7) Technical Requirements

- Implemented in SwiftUI with platform conditionals as needed.
- Shared core rendering model across iOS/iPadOS/macOS where feasible.
- Clean separation between:
  - data providers (system state acquisition),
  - view model/state management,
  - adaptive layout computation,
  - visual components.

## 8) Acceptance Criteria

### 8.1 Functional Acceptance
- User can enable/disable each supported indicator.
- Preferences persist after app relaunch.
- Enabled indicators appear in dashboard immediately after settings changes.
- Dashboard remains non-scrolling across supported sizes and orientations.
- Battery percentage-first mode remains legible without relying on color.
- Battery-driven brightness mapping follows the squared formula with a 10% floor when enabled.
- Status bar defaults to hidden and can be toggled where supported.
- Time/date and optional seconds format render correctly and update in real time.

### 8.2 Visual Acceptance
- Battery/volume/playback/connectivity states are legible from across a typical room.
- Layout remains balanced and readable when 1, few, or all indicators are enabled.

### 8.3 Performance Acceptance
- No continuous high-CPU loops in steady state.
- UI remains responsive during resize, orientation changes, and state updates.

### 8.4 Cross-Platform Acceptance
- App compiles and runs on iPhone, iPad, and macOS targets.
- iPad and macOS resizing triggers correct layout reflow without clipping essential content.

## 9) Risks and Mitigations

- **Risk:** Some system states may be restricted or unavailable by API.
  - **Mitigation:** define per-platform capability matrix and fallback visuals.
- **Risk:** Non-scrolling masonry can become crowded on small windows with many tiles enabled.
  - **Mitigation:** priority-based scaling rules and minimum legible size constraints.
- **Risk:** Frequent state polling could increase battery/CPU usage.
  - **Mitigation:** prefer event-driven updates and change-detection before rerender.

## 10) Milestones (Suggested)

1. **M1 - Foundation:** app shell, black background dashboard, settings entry point.
2. **M2 - Core Indicators:** battery, volume, playback tiles.
3. **M3 - Connectivity Indicators:** Wi-Fi, Bluetooth, speaker, ringer/silent handling.
4. **M4 - Adaptive Masonry:** non-scrolling responsive tile layout and resize behavior.
5. **M5 - Optimization and QA:** performance tuning, platform validation, edge-case handling.

## 11) Open Questions

1. Should users be able to pin indicator priority/order manually in Phase 1?
2. Should there be optional color themes, or strictly monochrome + status accents?
3. What exact minimum text/icon size defines "across the room" acceptance?
4. Should macOS include menu-bar shortcuts, or remain app-window only?
