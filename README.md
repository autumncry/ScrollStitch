# ScrollStitch

ScrollStitch is an open-source iOS app for turning scrolling content into a single long screenshot.

The app supports two local workflows:

- Import several overlapping screenshots from Photos and stitch them automatically.
- Import a system screen recording, extract scrolling frames, then stitch the useful frames into one long image.

The app is built with SwiftUI, PhotosUI, AVFoundation, Photos, and UIKit/CoreGraphics. Media is processed locally, and the project is intended to be deployable with a personal Apple Developer team from Xcode.

## Features

- Native SwiftUI interface for iPhone.
- Screenshot picker for importing overlapping screenshots in order.
- Screen-recording import for scrolling captures from any app that the user records with iOS Screen Recording.
- Vertical overlap detection and duplicate-region removal.
- Adjustable overlap, match tolerance, frame interval, and frame count settings.
- Long-image preview, Photos save, and system share export.
- Local-only media processing.

## iOS Screen Recording Boundary

iOS does not allow a third-party app to silently capture or control another app's scrolling content. ScrollStitch therefore uses user-mediated workflows:

1. Take multiple screenshots and import them.
2. Use iOS Screen Recording while scrolling the target content, stop recording, then import the video from Photos.

This keeps the implementation App Store-safe and deployable without private APIs.

## Requirements

- Xcode 26.5 or newer
- iOS 17.0 or newer
- XcodeGen 2.43 or newer
- A personal Apple Developer team for installing on a physical iPhone

## Generate The Xcode Project

```bash
xcodegen generate
```

## Build And Test

```bash
xcodebuild -project ScrollStitch.xcodeproj -scheme ScrollStitch -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
xcodebuild -project ScrollStitch.xcodeproj -scheme ScrollStitch -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

## Install On Your iPhone

1. Open `ScrollStitch.xcodeproj` after running `xcodegen generate`.
2. Select the `ScrollStitch` target.
3. Set Team to your Apple Developer team.
4. Keep the bundle identifier unique, for example `com.yourname.ScrollStitch`.
5. Connect your iPhone, choose it as the run destination, then press Run.

The checked-in project configuration uses development team `49S7RK7S28`, matching the local development certificate that was available when this project was created. Change it in Xcode or `project.yml` if needed.

## Demo Media

Generate two overlapping PNG screenshots for quick manual testing:

```bash
python3 Scripts/make_demo_media.py
```

The generated files land in `DemoMedia/`.

## Design

- Figma design reference: https://www.figma.com/design/73mHry8hcN6S9dqK79x7yP
- Architecture notes: [docs/architecture/overview.md](docs/architecture/overview.md)

## Privacy

ScrollStitch only processes screenshots and videos the user explicitly selects. The stitching pipeline runs on device.
