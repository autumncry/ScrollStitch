import SwiftUI
import WebKit

struct WebPageView: UIViewRepresentable {
    @ObservedObject var session: WebCaptureSession

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        session.attach(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        session.attach(webView)
    }
}
