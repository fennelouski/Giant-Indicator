# Native App Store release

Giant Indicator uses one native SwiftUI target for iOS and iPadOS 17.6 or later and macOS 14.6 or later. The refined release uses the existing bundle identifier, version 1.0, and build 6, archived from revision `b69386434e152281f9eb0b6ffddfc217248d35e9`.

macOS version 1.0 (6) is **Waiting for Review**, submitted October 2, 2026 at 22:52 Europe/Amsterdam. [Apple submission 620e3f0c-e167-482d-bf23-d299f9e6b2fb](https://appstoreconnect.apple.com/apps/6818551777/distribution/reviewsubmissions/details/620e3f0c-e167-482d-bf23-d299f9e6b2fb) contains processed build `2a32ef17-cb29-40c8-8bc8-16cae6746649`. Apple's downloaded copies of all ten Mac screenshots match the approved images' dimensions and RGB pixels. The previous Mac build 3 submission was removed before replacement.

iOS and iPadOS version 1.0 (6), processed build `0deb4c74-c29f-4119-9557-2f0e1341ac6a`, is selected and saved in **Prepare for Submission**. Its ten iPhone screenshots match Apple's downloaded copies exactly. Six iPad screenshots completed; uploads 07–10 remain unfinished in App Store Connect, which disables their deletion. The iOS submission is incomplete until those assets are repaired and Apple shows Waiting for Review. App Store Connect API access is disabled; enabling access and creating a locally stored App Manager key requires the user's pending approval. The previous [iOS build 4 submission](https://appstoreconnect.apple.com/apps/6818551777/distribution/reviewsubmissions/details/c3b2a08c-532c-4817-93fa-20960e395ab7) was removed before replacement; its historical receipts remain intact.

Both final build 6 archives, signing checks, uploads and native Release builds passed. Twenty platform and masonry checks passed for the refined layout logic. Genuine Mac, phone and iPad verification covered compact cell spacing, bounded dashboard widths, light and dark appearances, settings retained after full relaunch, and enlarged text with increased contrast. Physical battery, live weather retrieval and hardware brightness behavior were not verified on a physical device. Final receipts, genuine captures and screenshot provenance are retained in the workspace release audit at `app-store-audit/2026-10-02-giant-indicator/refinement/`; the earlier `ios/` and macOS release receipts preserve the previous submission history.

visionOS work is stopped at the user's request. Preserve its existing source, archive, upload and draft. Do not build, boot, run, capture, upload or submit visionOS until the user explicitly resumes that work.

Run `python3 Tools/check-platform-logic.py` for the production volume mapping, location request coalescing, platform visibility, permission education and isolated preference checks. Native interface verification must also cover section selection, permission cancellation, available device signals and settings retained after relaunch. The Mac release UI test requires a working Xcode UI automation session; a compiled test runner alone is not a passing test.

Archive the committed iOS revision for `generic/platform=iOS` with the Giant Indicator scheme, Release configuration, automatic signing and `-allowProvisioningUpdates`. Keep the production iOS entitlements. App Store Connect export uses the existing signed-in Xcode account and automatic distribution signing.

Capture the real iPhone and iPad interfaces and device values for their galleries. Do not use UI-test sensor overrides in store images. Complete the privacy, age rating, support and review details, select the processed build, and submit the iOS version for review.

Record the source revision, archive and upload results, gallery hashes and App Store Connect status in the release audit. Submission is complete only when Apple shows **Waiting for Review** for iOS.
