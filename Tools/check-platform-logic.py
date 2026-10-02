#!/usr/bin/env python3
"""Run actual platform helpers and selected unit checks without launching the app."""

import hashlib
import os
import re
from pathlib import Path
import subprocess
import tempfile
import uuid


ROOT = Path(__file__).resolve().parents[1]

for name in ("VolumeProvider.swift", "ConnectivityProvider.swift"):
    source = (ROOT / "Giant Indicator" / name).read_text()
    assert not re.search(r"\.(?:setActive|setCategory)\s*\(", source), name + " must read audio passively"
print("PASS: production volume/route providers never activate or configure an audio session", flush=True)


def declaration(source: str, anchor: str) -> str:
    start = source.index(anchor)
    opening = source.index("{", start)
    depth = 1
    cursor = opening + 1
    while depth:
        depth += (source[cursor] == "{") - (source[cursor] == "}")
        cursor += 1
    return source[start:cursor]


pieces = ["import Foundation\nimport SwiftUI\nimport CoreLocation\nimport Combine\n"]
for name in (
    "VolumeState.swift", "IndicatorKind.swift", "ClockTypography.swift", "ClockState.swift",
    "BatteryDrivenScreenBrightness.swift", "StatusBarVisibility.swift",
    "DashboardPalette.swift", "BatteryReflectiveBackground.swift",
):
    pieces.append((ROOT / "Giant Indicator" / name).read_text())

for name in (
    "PermissionKind.swift", "PermissionAuthorizationStatus.swift",
    "PermissionEducationPreferences.swift", "IndicatorPreferences.swift", "PermissionGateCoordinator.swift",
):
    pieces.append((ROOT / "Giant Indicator" / name).read_text())
display_source = (ROOT / "Giant Indicator/DisplayPreferences.swift").read_text()
pieces.append("enum DisplayPreferences {\n" + declaration(display_source, "static let defaults: UserDefaults =") + "()\n}")

for filename, anchors in (
    ("IndicatorFallbackPresentation.swift", ["protocol IndicatorUnavailablePresenting"]),
    ("VolumeProvider.swift", ["enum VolumeSnapshotResolver"]),
    ("WeatherLocationProvider.swift", ["enum WeatherLocationResolution", "@MainActor\nfinal class WeatherLocationRequest"]),
):
    source = (ROOT / "Giant Indicator" / filename).read_text()
    pieces.extend(declaration(source, anchor) for anchor in anchors)

tests = (ROOT / "Giant IndicatorTests/Giant_IndicatorTests.swift").read_text()
methods = (
    "volumeSnapshot_resolvesDeviceCapabilitiesWithoutInventingValues",
    "weatherLocationRequest_coalescesReadersAndCanStartAgain",
    "indicatorKind_defaultVisibilityMatchesDashboardFavorites",
    "screenBrightnessControl_matchesPlatformSupport",
    "statusBarVisibilityControl_matchesPlatformSupport",
    "indicatorKind_settingsGroupMapping",
    "clockTypography_shrinksFontToFitNarrowWidthWithoutTruncating",
    "clockTypography_usesMaxFontWhenWidthAllows",
    "permissionKind_mapsIndicatorRequirements",
)
checks = [
    declaration(tests, "@Test func " + method)
    .replace("@Test func ", "static func ", 1)
    .replace("#expect(", "check(")
    for method in methods
]
pieces.append("@main @MainActor struct Checks {\n")
pieces.append("static func check(_ condition: Bool) { precondition(condition) }\n")
pieces.extend(checks)
background_source = (ROOT / "Giant Indicator/ContentView.swift").read_text()
pieces.append('''
struct DashboardFixture {
    struct BatteryState { var percentage = 100; var isDataAvailable = true }
    struct BatteryModel { var state = BatteryState() }
    var batteryViewModel = BatteryModel()
    var batteryReflectiveBackground = false
    var backgroundAppearance = DashboardBackgroundAppearance.dark
    var colorScheme = ColorScheme.light
''')
pieces.append(declaration(background_source, "private var dashboardBackground: Color").replace("private var", "var", 1))
pieces.append('''
}
static func dashboardBackground_matchesVisibleTextPalette() {
    var dashboard = DashboardFixture()
    check(dashboard.dashboardBackground == Color.black)
    dashboard.backgroundAppearance = .light
    check(dashboard.dashboardBackground == Color.white)
    dashboard.backgroundAppearance = .system
    check(dashboard.dashboardBackground == Color.white)
    dashboard.colorScheme = .dark
    check(dashboard.dashboardBackground == Color.black)
    dashboard.batteryReflectiveBackground = true
    check(dashboard.dashboardBackground == DashboardPalette(batteryPercentage: 100).background)
    dashboard.batteryViewModel.state.isDataAvailable = false
    check(dashboard.dashboardBackground == DashboardPalette(batteryPercentage: 0).background)
}
''')
pieces.append('''
struct BatteryMotionFixture {
    var chargingPulse = false
    var isPluggedIn = false
    var animatesLevelChanges = false
    var reduceMotion = false
''')
battery_icon_source = (ROOT / "Giant Indicator/BatteryIcon.swift").read_text()
for anchor in ("private var chargingPulseActive: Bool", "private var levelAnimation: Animation?"):
    pieces.append(declaration(battery_icon_source, anchor).replace("private var", "var", 1))
pieces.append('''
}
static func batteryMotion_respectsSystemPreference() {
    var battery = BatteryMotionFixture()
    check(!battery.chargingPulseActive && battery.levelAnimation == nil)
    battery.chargingPulse = true
    check(!battery.chargingPulseActive)
    battery.isPluggedIn = true
    battery.animatesLevelChanges = true
    check(battery.chargingPulseActive && battery.levelAnimation != nil)
    battery.reduceMotion = true
    check(!battery.chargingPulseActive && battery.levelAnimation == nil)
    battery.reduceMotion = false
    check(battery.chargingPulseActive && battery.levelAnimation != nil)
    battery.isPluggedIn = false
    check(!battery.chargingPulseActive)
}
''')
pieces.append('''
static func wifiNetworkNameGate_preservesOtherIndicators() {
    guard let suite = ProcessInfo.processInfo.environment["GIANT_INDICATOR_QA_DEFAULTS_SUITE"],
          suite.hasPrefix("giant-indicator.qa."),
          ProcessInfo.processInfo.arguments.contains("--ui-testing-force-permission-not-determined") else {
        preconditionFailure("An isolated suite and no-manager permission fixture are required")
    }
    let defaults = DisplayPreferences.defaults
    defaults.removePersistentDomain(forName: suite)
    defer {
        defaults.removePersistentDomain(forName: suite)
        defaults.synchronize()
        check(defaults.persistentDomain(forName: suite) == nil)
    }
    let gate = PermissionGateCoordinator()
    var visibility = IndicatorKind.defaultVisibilityState
    visibility[.weather] = false
    IndicatorPreferences.setVisibility(false, for: .weather)
    gate.setIndicatorVisibility(true, for: .wifi, currentVisibility: &visibility)
    check(gate.pendingAlert == nil)
    let before = visibility
    var nameEnableCount = 0
    gate.onWiFiNetworkNameEnabled = { nameEnableCount += 1 }
    gate.enableWiFiNetworkName(currentVisibility: &visibility)
    check(gate.pendingAlert?.permission == .location)
    check(gate.pendingAlert?.message.contains("Basic Wi-Fi status") == true)
    check(visibility == before && nameEnableCount == 0)
    gate.cancelEducation(currentVisibility: &visibility)
    check(gate.pendingAlert == nil)
    check(visibility == before && nameEnableCount == 0)
    check(!PermissionEducationPreferences.hasSeenEducation(for: .location))
    gate.enableWiFiNetworkName(currentVisibility: &visibility)
    gate.confirmEducation(currentVisibility: &visibility)
    check(gate.pendingAlert == nil && nameEnableCount == 1)
    check(visibility == before)
    check(!defaults.bool(forKey: IndicatorKind.weather.visibilityStorageKey))
    check(PermissionEducationPreferences.hasSeenEducation(for: .location))
    gate.enableWiFiNetworkName(currentVisibility: &visibility)
    check(gate.pendingAlert == nil && nameEnableCount == 2)
    check(visibility == before)
}
''')
pieces.append("static func main() async throws {\n")
pieces.append('''
if ProcessInfo.processInfo.arguments.contains("--verify-own-domain-cleanup") {
    let suite = ProcessInfo.processInfo.environment["GIANT_INDICATOR_QA_DEFAULTS_SUITE"]!
    check(suite.hasPrefix("giant-indicator.qa."))
    check(DisplayPreferences.defaults.persistentDomain(forName: suite) == nil)
    print("PASS: fresh-process owned preference domain cleanup")
    return
}
''')
pieces.extend("try await " + method + "()\n" for method in methods)
pieces.append("wifiNetworkNameGate_preservesOtherIndicators()\n")
pieces.append("dashboardBackground_matchesVisibleTextPalette()\n")
pieces.append("batteryMotion_respectsSystemPreference()\n")
pieces.append('print("PASS: twelve checks: nine actual unit checks, Wi-Fi permission gate, exact production background contrast and Reduce Motion battery gating; no app, location manager or audio device instantiated")\n}\n}\n')
source = "\n".join(pieces)
print("Extracted source SHA256", hashlib.sha256(source.encode()).hexdigest(), flush=True)
with tempfile.TemporaryDirectory(prefix="giant-indicator-platform-check-") as directory:
    source_file = Path(directory) / "Checks.swift"
    executable = Path(directory) / "checks"
    source_file.write_text(source)
    subprocess.run([
        "xcrun", "swiftc", "-swift-version", "5", "-parse-as-library",
        "-default-isolation", "MainActor", str(source_file), "-o", str(executable),
    ], check=True)
    environment = dict(os.environ, GIANT_INDICATOR_QA_DEFAULTS_SUITE="giant-indicator.qa." + str(uuid.uuid4()))
    subprocess.run([str(executable), "--ui-testing-force-permission-not-determined"], env=environment, check=True)
    subprocess.run([str(executable), "--verify-own-domain-cleanup"], env=environment, check=True)
