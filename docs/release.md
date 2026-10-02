# Native App Store release

Giant Indicator uses one native SwiftUI target for iOS and iPadOS 17.6 or later and macOS 14.6 or later. The iOS release uses the existing bundle identifier, version 1.0, and build 4. macOS build 3 is already waiting for Apple review.

iOS and iPadOS version 1.0 (4) are **Waiting for Review**, submitted October 2, 2026 at 20:41 Europe/Amsterdam. [Apple submission c3b2a08c-532c-4817-93fa-20960e395ab7](https://appstoreconnect.apple.com/apps/6818551777/distribution/reviewsubmissions/details/c3b2a08c-532c-4817-93fa-20960e395ab7) contains processed build `2ab318b4-b0dd-49e5-a79a-bfd50b00b799`, archived from revision `4ee0e75e538875e5c138d74c026d4c47ff545451`. Archive, signing, upload and 12 platform logic checks passed. Native phone/iPad verification covered settings, permission cancellation, appearance, clock/date, unavailable device signals and preferences retained after full relaunch. Ten screenshots per device family were uploaded; Apple's downloaded copies match every approved image's dimensions and RGB pixels. Physical battery, live weather retrieval and hardware brightness behavior were not verified on a physical device. Receipts and genuine captures are retained in the workspace release audit at `app-store-audit/2026-10-02-giant-indicator/ios/`.

visionOS work is stopped at the user's request. Preserve its existing source, archive, upload and draft. Do not build, boot, run, capture, upload or submit visionOS until the user explicitly resumes that work.

Run `python3 Tools/check-platform-logic.py` for the production volume mapping, location request coalescing, platform visibility, permission education and isolated preference checks. Native interface verification must also cover section selection, permission cancellation, available device signals and settings retained after relaunch. The Mac release UI test requires a working Xcode UI automation session; a compiled test runner alone is not a passing test.

Archive the committed iOS revision for `generic/platform=iOS` with the Giant Indicator scheme, Release configuration, automatic signing and `-allowProvisioningUpdates`. Keep the production iOS entitlements. App Store Connect export uses the existing signed-in Xcode account and automatic distribution signing.

Capture the real iPhone and iPad interfaces and device values for their galleries. Do not use UI-test sensor overrides in store images. Complete the privacy, age rating, support and review details, select the processed build, and submit the iOS version for review.

Record the source revision, archive and upload results, gallery hashes and App Store Connect status in the release audit. Submission is complete only when Apple shows **Waiting for Review** for iOS.
