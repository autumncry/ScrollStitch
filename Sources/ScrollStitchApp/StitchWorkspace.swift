import PhotosUI
import ScrollStitchCore
import SwiftUI

@MainActor
final class StitchWorkspace: ObservableObject {
    enum ImportMode: String, CaseIterable, Identifiable {
        case screenshots
        case recording

        var id: String { rawValue }

        var title: String {
            switch self {
            case .screenshots: "Screenshots"
            case .recording: "Recording"
            }
        }

        var importTitle: String {
            switch self {
            case .screenshots: "Import overlapping screenshots"
            case .recording: "Import a scrolling screen recording"
            }
        }

        var importSubtitle: String {
            switch self {
            case .screenshots:
                "Select screenshots in top-to-bottom order. The app removes repeated overlap locally."
            case .recording:
                "Record scrolling content with iOS Screen Recording, then choose the video from Photos."
            }
        }

        var symbolName: String {
            switch self {
            case .screenshots: "photo.stack"
            case .recording: "record.circle"
            }
        }
    }

    enum ProcessingState {
        case idle
        case loading(String)
        case stitching
        case saving
        case success(String)
        case failure(String)

        var isBusy: Bool {
            switch self {
            case .loading, .stitching, .saving: true
            case .idle, .success, .failure: false
            }
        }

        var message: String {
            switch self {
            case .idle: "Ready"
            case .loading(let message): message
            case .stitching: "Building long screenshot..."
            case .saving: "Saving to Photos..."
            case .success(let message), .failure(let message): message
            }
        }

        var symbolName: String {
            switch self {
            case .idle: "checkmark.circle"
            case .loading, .stitching, .saving: "hourglass"
            case .success: "checkmark.circle.fill"
            case .failure: "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .failure: .red
            case .success: .green
            default: .secondary
            }
        }
    }

    @Published var mode: ImportMode = .screenshots
    @Published var selectedImages: [UIImage] = []
    @Published var selectedVideoURL: URL?
    @Published var selectedVideoName: String?
    @Published var resultImage: UIImage?
    @Published var state: ProcessingState = .idle

    @Published var minimumOverlap: Double = 16
    @Published var maximumOverlap: Double = 420
    @Published var mismatchThreshold: Double = 10
    @Published var frameInterval: Double = 0.45
    @Published var maximumFrameCount: Double = 60

    private let videoFrameExtractor = VideoFrameExtractor()

    var canStitch: Bool {
        switch mode {
        case .screenshots:
            selectedImages.count >= 2
        case .recording:
            selectedVideoURL != nil
        }
    }

    func loadImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            selectedImages = []
            state = .idle
            return
        }

        state = .loading("Loading \(items.count) screenshots...")

        do {
            var images: [UIImage] = []
            for item in items {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image.normalizedForStitching())
                }
            }

            selectedImages = images
            resultImage = nil
            state = images.count >= 2
                ? .success("Loaded \(images.count) screenshots")
                : .failure("Choose at least two screenshots")
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    func loadVideo(from item: PhotosPickerItem?) async {
        guard let item else {
            selectedVideoURL = nil
            selectedVideoName = nil
            state = .idle
            return
        }

        state = .loading("Loading recording...")

        do {
            guard let movie = try await item.loadTransferable(type: ScreenRecordingMovie.self) else {
                state = .failure("Could not load the selected recording")
                return
            }

            selectedVideoURL = movie.url
            selectedVideoName = movie.url.lastPathComponent
            resultImage = nil
            state = .success("Recording ready")
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    func stitch() async {
        state = .stitching

        do {
            let sourceImages: [UIImage]
            switch mode {
            case .screenshots:
                sourceImages = selectedImages
            case .recording:
                guard let selectedVideoURL else {
                    state = .failure("Choose a screen recording first")
                    return
                }
                let policy = VideoFrameSamplingPolicy(
                    interval: frameInterval,
                    maximumFrameCount: Int(maximumFrameCount)
                )
                sourceImages = try await videoFrameExtractor.extractFrames(from: selectedVideoURL, policy: policy)
            }

            let stitcher = VerticalStitcher(
                minimumOverlap: Int(minimumOverlap),
                maximumOverlap: Int(maximumOverlap),
                mismatchThreshold: mismatchThreshold,
                sampleStride: 3
            )
            resultImage = try stitcher.stitch(sourceImages)
            state = .success("Long screenshot is ready")
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    func saveResult() async {
        guard let resultImage else { return }

        state = .saving

        do {
            try await PhotoLibraryWriter.save(resultImage)
            state = .success("Saved to Photos")
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    func exportResultForSharing() -> ShareFile? {
        guard let resultImage,
              let data = resultImage.pngData() else {
            return nil
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScrollStitch-\(UUID().uuidString)")
            .appendingPathExtension("png")

        do {
            try data.write(to: url, options: [.atomic])
            return ShareFile(url: url)
        } catch {
            state = .failure(error.localizedDescription)
            return nil
        }
    }
}

private extension UIImage {
    func normalizedForStitching() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
