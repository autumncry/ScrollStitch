import ScrollStitchCore
import SwiftUI
import WebKit

@MainActor
final class WebCaptureSession: NSObject, ObservableObject {
    enum CaptureState: Equatable {
        case idle
        case loading
        case ready(String)
        case capturing(Double)
        case saving
        case success(String)
        case failure(String)

        var isBusy: Bool {
            switch self {
            case .loading, .capturing, .saving: true
            case .idle, .ready, .success, .failure: false
            }
        }

        var message: String {
            switch self {
            case .idle: "Ready"
            case .loading: "Loading page..."
            case .ready(let title): title.isEmpty ? "Page ready" : title
            case .capturing(let progress): "Capturing \(Int((progress * 100).rounded()))%"
            case .saving: "Saving to Photos..."
            case .success(let message), .failure(let message): message
            }
        }

        var symbolName: String {
            switch self {
            case .idle, .ready: "checkmark.circle"
            case .loading: "globe"
            case .capturing: "camera.viewfinder"
            case .saving: "square.and.arrow.down"
            case .success: "checkmark.circle.fill"
            case .failure: "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .failure: .red
            case .success: .green
            case .capturing: .blue
            default: .secondary
            }
        }

        var progress: Double? {
            if case .capturing(let progress) = self {
                return progress
            }
            return nil
        }
    }

    @Published var addressText = "https://www.apple.com/iphone/"
    @Published var title = "ScrollStitch"
    @Published var state: CaptureState = .idle
    @Published var resultImage: UIImage?
    @Published var canGoBack = false
    @Published var canGoForward = false

    private weak var webView: WKWebView?
    private var didLoadInitialPage = false

    var canCapture: Bool {
        webView != nil && !state.isBusy
    }

    func attach(_ webView: WKWebView) {
        guard self.webView !== webView else { return }

        self.webView = webView
        webView.navigationDelegate = self

        guard !didLoadInitialPage else { return }
        didLoadInitialPage = true
        Task { @MainActor in
            loadAddress()
        }
    }

    func loadAddress() {
        guard let url = Self.normalizedURL(from: addressText) else {
            state = .failure("Enter a valid URL")
            return
        }

        addressText = url.absoluteString
        resultImage = nil
        state = .loading
        webView?.load(URLRequest(url: url))
    }

    func reload() {
        resultImage = nil
        state = .loading
        webView?.reload()
    }

    func goBack() {
        webView?.goBack()
        updateNavigationState()
    }

    func goForward() {
        webView?.goForward()
        updateNavigationState()
    }

    func captureFullPage() async {
        guard let webView else {
            state = .failure("Page is not ready")
            return
        }

        resultImage = nil
        state = .capturing(0)

        do {
            let image = try await WebPageLongScreenshotCapturer.capture(webView: webView) { [weak self] progress in
                self?.state = .capturing(progress)
            }
            resultImage = image
            state = .success("Captured \(Int(image.size.width)) x \(Int(image.size.height))")
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
            .appendingPathComponent("ScrollStitch-Web-\(UUID().uuidString)")
            .appendingPathExtension("png")

        do {
            try data.write(to: url, options: [.atomic])
            return ShareFile(url: url)
        } catch {
            state = .failure(error.localizedDescription)
            return nil
        }
    }

    static func normalizedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: candidate),
              let host = url.host(),
              !host.isEmpty else {
            return nil
        }

        return url
    }

    private func updateNavigationState() {
        guard let webView else { return }

        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        title = webView.title ?? "ScrollStitch"
    }
}

extension WebCaptureSession: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        state = .loading
        updateNavigationState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateNavigationState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateNavigationState()
        state = .ready(webView.title ?? "")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateNavigationState()
        state = .failure(error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateNavigationState()
        state = .failure(error.localizedDescription)
    }
}

private enum WebPageCaptureError: LocalizedError {
    case hiddenWebView
    case snapshotFailed
    case pageTooLarge

    var errorDescription: String? {
        switch self {
        case .hiddenWebView: "Open a loaded page before capturing"
        case .snapshotFailed: "Could not capture the current page"
        case .pageTooLarge: "This page is too tall to render safely"
        }
    }
}

@MainActor
private enum WebPageLongScreenshotCapturer {
    private static let settleDelayNanoseconds: UInt64 = 140_000_000
    private static let maximumRenderedPixels: CGFloat = 120_000_000

    static func capture(
        webView: WKWebView,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> UIImage {
        webView.layoutIfNeeded()

        let viewportSize = webView.bounds.size
        guard viewportSize.width > 0, viewportSize.height > 0 else {
            throw WebPageCaptureError.hiddenWebView
        }

        let scrollView = webView.scrollView
        let originalOffset = scrollView.contentOffset
        defer {
            scrollView.setContentOffset(originalOffset, animated: false)
        }

        let contentHeight = ceil(try await resolvedContentHeight(for: webView))
        let renderedPixelCount = viewportSize.width * contentHeight * pow(UIScreen.main.scale, 2)
        guard renderedPixelCount <= maximumRenderedPixels else {
            throw WebPageCaptureError.pageTooLarge
        }

        let slices = try PageCapturePlan.slices(
            contentHeight: contentHeight,
            viewportHeight: viewportSize.height
        )

        var captures: [(slice: PageCaptureSlice, image: UIImage)] = []
        captures.reserveCapacity(slices.count)

        for (index, slice) in slices.enumerated() {
            scrollView.setContentOffset(CGPoint(x: 0, y: slice.contentOffsetY), animated: false)
            scrollView.layoutIfNeeded()
            webView.layoutIfNeeded()
            try await Task.sleep(nanoseconds: settleDelayNanoseconds)

            let image = try await snapshot(webView: webView, size: viewportSize)
            captures.append((slice, image))
            progressHandler(Double(index + 1) / Double(slices.count))
        }

        guard let scale = captures.first?.image.scale else {
            throw WebPageCaptureError.snapshotFailed
        }

        let outputSize = CGSize(width: viewportSize.width, height: contentHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        return renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))

            for capture in captures {
                let slice = capture.slice
                let drawRect = CGRect(
                    x: 0,
                    y: slice.drawY - slice.sourceY,
                    width: outputSize.width,
                    height: capture.image.size.height
                )
                let clipRect = CGRect(x: 0, y: slice.drawY, width: outputSize.width, height: slice.height)

                context.cgContext.saveGState()
                context.cgContext.clip(to: clipRect)
                capture.image.draw(in: drawRect)
                context.cgContext.restoreGState()
            }
        }
    }

    private static func resolvedContentHeight(for webView: WKWebView) async throws -> CGFloat {
        let script = """
        Math.max(
          document.body ? document.body.scrollHeight : 0,
          document.documentElement ? document.documentElement.scrollHeight : 0,
          document.body ? document.body.offsetHeight : 0,
          document.documentElement ? document.documentElement.offsetHeight : 0,
          document.documentElement ? document.documentElement.clientHeight : 0
        )
        """

        let scriptValue = try await webView.evaluateJavaScript(script)
        let scriptHeight: CGFloat

        if let number = scriptValue as? NSNumber {
            scriptHeight = CGFloat(truncating: number)
        } else if let double = scriptValue as? Double {
            scriptHeight = CGFloat(double)
        } else {
            scriptHeight = 0
        }

        return max(webView.scrollView.contentSize.height, scriptHeight, webView.bounds.height)
    }

    private static func snapshot(webView: WKWebView, size: CGSize) async throws -> UIImage {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UIImage, Error>) in
            let configuration = WKSnapshotConfiguration()
            configuration.rect = CGRect(origin: .zero, size: size)

            webView.takeSnapshot(with: configuration) { image, error in
                if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: error ?? WebPageCaptureError.snapshotFailed)
                }
            }
        }
    }
}
