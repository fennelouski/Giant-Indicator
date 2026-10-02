# Native App Store release

Giant Indicator uses one native SwiftUI target for macOS 14.6 or later and visionOS 2.0 or later. The release uses the existing bundle identifier, version 1.0, and build 2.

Run `python3 Tools/check-platform-logic.py` for the production volume mapping, location request coalescing, platform visibility, permission education and isolated preference checks. Native interface verification must also cover section selection, permission cancellation, available device signals and settings retained after relaunch. The Mac release UI test requires a working Xcode UI automation session; a compiled test runner alone is not a passing test.

Archive the same committed revision for `generic/platform=macOS` and `generic/platform=visionOS` with the Giant Indicator scheme, Release configuration, automatic signing and `-allowProvisioningUpdates`. Keep the platform-specific production entitlements. App Store Connect export uses the existing signed-in Xcode account and automatic distribution signing.

Capture each platform's real interface and device values for its own gallery. Do not use UI-test sensor overrides in store images. Complete the privacy, age rating, support, review contact and platform motion details, select the processed builds, and submit both versions for review.

Record the source revision, archive and upload results, gallery hashes and App Store Connect status in the release audit. Submission is complete only when Apple shows **Waiting for Review** for both platforms.
