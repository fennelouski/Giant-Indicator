# Native App Store release

Giant Indicator uses one native SwiftUI target for iOS and iPadOS 17.6 or later and macOS 14.6 or later. The iOS release uses the existing bundle identifier, version 1.0, and build 4. macOS build 3 is already waiting for Apple review.

visionOS work is stopped at the user's request. Preserve its existing source, archive, upload and draft. Do not build, boot, run, capture, upload or submit visionOS until the user explicitly resumes that work.

Run `python3 Tools/check-platform-logic.py` for the production volume mapping, location request coalescing, platform visibility, permission education and isolated preference checks. Native interface verification must also cover section selection, permission cancellation, available device signals and settings retained after relaunch. The Mac release UI test requires a working Xcode UI automation session; a compiled test runner alone is not a passing test.

Archive the committed iOS revision for `generic/platform=iOS` with the Giant Indicator scheme, Release configuration, automatic signing and `-allowProvisioningUpdates`. Keep the production iOS entitlements. App Store Connect export uses the existing signed-in Xcode account and automatic distribution signing.

Capture the real iPhone and iPad interfaces and device values for their galleries. Do not use UI-test sensor overrides in store images. Complete the privacy, age rating, support and review details, select the processed build, and submit the iOS version for review.

Record the source revision, archive and upload results, gallery hashes and App Store Connect status in the release audit. Submission is complete only when Apple shows **Waiting for Review** for iOS.
