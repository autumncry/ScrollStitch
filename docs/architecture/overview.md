# Architecture Overview

ScrollStitch is split into a reusable capture/stitching framework and a native iOS app shell.

## Targets

- `ScrollStitchCore`: framework with page capture planning, image stitching, and video frame sampling policy.
- `ScrollStitch`: SwiftUI app for in-app web capture, importing media, previewing output, saving, and sharing.
- `ScrollStitchCoreTests`: iOS simulator unit tests for core behavior.

## Web Capture Pipeline

1. Load a URL in the app-owned `WKWebView`.
2. Resolve the page height from WebKit and the DOM.
3. Build a `PageCapturePlan` from page height and viewport height.
4. Scroll the web view to each planned offset.
5. Capture each visible viewport with `WKWebView.takeSnapshot`.
6. Crop the final viewport to avoid duplicated bottom rows.
7. Render one long PNG and restore the original scroll position.

This workflow supports automatic scrolling for pages opened inside ScrollStitch.

## Media Stitching Pipeline

1. Import screenshots from Photos or extract frames from a selected screen recording.
2. Normalize image orientation.
3. For each adjacent pair, rasterize images into comparable RGBA buffers.
4. Search for the best vertical overlap between the current stitched image bottom and the next image top.
5. Render the next image starting above its duplicated overlap.
6. Save or share the final PNG.

## iOS Boundary

The app does not use private APIs or background capture. Public iOS APIs do not let one app programmatically scroll and capture another app. For external apps, users can still record scrolling content with iOS Screen Recording, then import the saved video. `VideoFrameExtractor` samples frames with AVFoundation and sends the frames through the same stitching pipeline as screenshots.

## Design Principles

- Keep all media processing local.
- Prefer simple SwiftUI state and native controls.
- Keep algorithmic code in `ScrollStitchCore` so it is testable without UI.
- Avoid committing generated Xcode project files; `project.yml` is the source of truth.
