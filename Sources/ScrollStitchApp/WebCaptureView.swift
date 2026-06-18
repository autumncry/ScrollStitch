import SwiftUI

struct WebCaptureView: View {
    @ObservedObject var session: WebCaptureSession
    @FocusState private var isAddressFocused: Bool
    @State private var isShowingResult = false
    @State private var shareFile: ShareFile?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                addressBar
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                Divider()

                WebPageView(session: session)
                    .overlay(alignment: .bottom) {
                        statusStrip
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                    }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Long Screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .sheet(isPresented: $isShowingResult) {
                resultSheet
            }
            .sheet(item: $shareFile) { file in
                ShareSheet(items: [file.url])
            }
        }
    }

    private var addressBar: some View {
        HStack(spacing: 8) {
            Button {
                session.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 30, height: 30)
            }
            .disabled(!session.canGoBack || session.state.isBusy)
            .accessibilityLabel("Back")

            Button {
                session.goForward()
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 30, height: 30)
            }
            .disabled(!session.canGoForward || session.state.isBusy)
            .accessibilityLabel("Forward")

            TextField("URL", text: $session.addressText)
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($isAddressFocused)
                .onSubmit {
                    isAddressFocused = false
                    session.loadAddress()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            Button {
                session.reload()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 30, height: 30)
            }
            .disabled(session.state.isBusy)
            .accessibilityLabel("Reload")

            Button {
                isAddressFocused = false
                session.loadAddress()
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .frame(width: 30, height: 30)
            }
            .disabled(session.state.isBusy)
            .accessibilityLabel("Go")
        }
        .buttonStyle(.plain)
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            if let progress = session.state.progress {
                ProgressView(value: progress)
                    .frame(width: 52)
            } else if session.state.isBusy {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: session.state.symbolName)
                    .foregroundStyle(session.state.tint)
            }

            Text(session.state.message)
                .font(.footnote)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                Task { await session.captureFullPage() }
            } label: {
                Label("Capture", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!session.canCapture)

            Button {
                isShowingResult = true
            } label: {
                Image(systemName: "doc.viewfinder")
                    .frame(width: 42, height: 32)
            }
            .buttonStyle(.bordered)
            .disabled(session.resultImage == nil || session.state.isBusy)
            .accessibilityLabel("Preview")

            Button {
                Task { await session.saveResult() }
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .frame(width: 42, height: 32)
            }
            .buttonStyle(.bordered)
            .disabled(session.resultImage == nil || session.state.isBusy)
            .accessibilityLabel("Save to Photos")

            Button {
                shareFile = session.exportResultForSharing()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 42, height: 32)
            }
            .buttonStyle(.bordered)
            .disabled(session.resultImage == nil || session.state.isBusy)
            .accessibilityLabel("Share")
        }
        .padding()
        .background(.bar)
    }

    @ViewBuilder
    private var resultSheet: some View {
        NavigationStack {
            if let image = session.resultImage {
                ResultPreview(image: image)
                    .padding()
                    .navigationTitle("Result")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isShowingResult = false
                            }
                        }
                    }
            } else {
                ContentUnavailableView("No Capture", systemImage: "doc.viewfinder")
                    .navigationTitle("Result")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    WebCaptureView(session: WebCaptureSession())
}
