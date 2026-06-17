# Architecture Overview

ScrollStitch is split into a reusable stitching framework and a native iOS app shell.

## Targets

- `ScrollStitchCore`: framework with image stitching and video frame sampling policy.
- `ScrollStitch`: SwiftUI app for importing media, previewing output, saving, and sharing.
- `ScrollStitchCoreTests`: iOS simulator unit tests for core behavior.

## Stitching Pipeline

1. Import screenshots from Photos or extract frames from a selected screen recording.
2. Normalize image orientation.
3. For each adjacent pair, rasterize images into comparable RGBA buffers.
4. Search for the best vertical overlap between the current stitched image bottom and the next image top.
5. Render the next image starting above its duplicated overlap.
6. Save or share the final PNG.

## Recording Workflow

The app does not use private APIs or background capture. Users record scrolling content with iOS Screen Recording, then import the saved video. `VideoFrameExtractor` samples frames with AVFoundation and sends the frames through the same stitching pipeline as screenshots.

## Design Principles

- Keep all media processing local.
- Prefer simple SwiftUI state and native controls.
- Keep algorithmic code in `ScrollStitchCore` so it is testable without UI.
- Avoid committing generated Xcode project files; `project.yml` is the source of truth.
