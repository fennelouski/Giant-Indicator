# Giant Indicator

A native dashboard with large, glanceable device status, time and date. Supports iPhone, iPad, Mac and Apple Vision Pro.

Double-tap or double-click the dashboard to open Settings. Mac also has a toolbar button and Command-comma; Vision has a visible Settings button. Choose a section on the left in wide windows, or use the section menu in compact layouts. Indicator choices, background, battery style and display options persist until changed.

## Platform features

| Feature | Mac | Apple Vision Pro | iPhone / iPad |
| --- | --- | --- | --- |
| Time and date, optional clock seconds | Yes | Yes | Yes |
| Battery and charging state | When the Mac has a battery | When reported by the device | Yes |
| Volume | CoreAudio output level; fixed-volume devices report unavailable | Device output volume | Device output volume |
| Wi-Fi connection | Yes | Yes | Yes |
| Wi-Fi signal strength | When the interface exposes RSSI | Unavailable through public APIs | Unavailable through public APIs |
| Wi-Fi network name | Optional, location permission required | Subject to platform availability | Optional, location permission required |
| Local weather | Optional location and Apple WeatherKit | Optional location and Apple WeatherKit | Optional location and Apple WeatherKit |
| Keep display awake | While the active dashboard is visible | Subject to system behavior | While the active dashboard is visible |
| Display brightness and status bar | Managed by macOS | Managed by visionOS | Optional app controls |

System-wide music metadata/playback and Bluetooth monitoring are not offered. Public Now Playing APIs describe this app's own media, and this dashboard does not play music.

## Support and privacy

- [Support](docs/support.md)
- [Privacy policy](docs/privacy.md)
- [Release verification](docs/release.md)

## Build

Open `Giant Indicator.xcodeproj` in Xcode and select the Giant Indicator scheme. Choose a Mac, Apple Vision Pro, iPhone or iPad destination. Signed weather requests require the app's registered WeatherKit capability. Native App Store release archives use platform-specific entitlements.
