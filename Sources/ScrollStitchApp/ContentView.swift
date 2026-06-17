import PhotosUI
import SwiftUI

struct ContentView: View {
    @StateObject private var workspace = StitchWorkspace()
    @State private var imageItems: [PhotosPickerItem] = []
    @State private var videoItem: PhotosPickerItem?
    @State private var isShowingSettings = false
    @State private var shareFile: ShareFile?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    modePicker
                    importPanel
                    previewPanel
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ScrollStitch")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(workspace: workspace)
            }
            .sheet(item: $shareFile) { file in
                ShareSheet(items: [file.url])
            }
            .onChange(of: imageItems) { _, newValue in
                Task { await workspace.loadImages(from: newValue) }
            }
            .onChange(of: videoItem) { _, newValue in
                Task { await workspace.loadVideo(from: newValue) }
            }
        }
    }

    private var modePicker: some View {
        Picker("Source", selection: $workspace.mode) {
            ForEach(StitchWorkspace.ImportMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Source mode")
    }

    private var importPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(workspace.mode.importTitle, systemImage: workspace.mode.symbolName)
                .font(.headline)

            Text(workspace.mode.importSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if workspace.mode == .screenshots {
                PhotosPicker(selection: $imageItems, maxSelectionCount: 24, matching: .images) {
                    Label("Choose Screenshots", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                SelectedImageStrip(images: workspace.selectedImages)
            } else {
                PhotosPicker(selection: $videoItem, matching: .videos) {
                    Label("Choose Screen Recording", systemImage: "record.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let selectedVideoName = workspace.selectedVideoName {
                    Label(selectedVideoName, systemImage: "film")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if workspace.state.isBusy {
                ProgressView(workspace.state.message)
            } else {
                Label(workspace.state.message, systemImage: workspace.state.symbolName)
                    .font(.footnote)
                    .foregroundStyle(workspace.state.tint)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Preview", systemImage: "doc.viewfinder")
                .font(.headline)

            if let resultImage = workspace.resultImage {
                ResultPreview(image: resultImage)
            } else {
                ContentUnavailableView(
                    "No Long Screenshot Yet",
                    systemImage: "rectangle.stack",
                    description: Text("Import screenshots or a scrolling screen recording, then tap Stitch.")
                )
                .frame(minHeight: 260)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                Task { await workspace.stitch() }
            } label: {
                Label("Stitch", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!workspace.canStitch || workspace.state.isBusy)

            Button {
                Task { await workspace.saveResult() }
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .frame(width: 42, height: 32)
            }
            .buttonStyle(.bordered)
            .disabled(workspace.resultImage == nil || workspace.state.isBusy)
            .accessibilityLabel("Save to Photos")

            Button {
                shareFile = workspace.exportResultForSharing()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 42, height: 32)
            }
            .buttonStyle(.bordered)
            .disabled(workspace.resultImage == nil || workspace.state.isBusy)
            .accessibilityLabel("Share")
        }
        .padding()
        .background(.bar)
    }
}

private struct SelectedImageStrip: View {
    let images: [UIImage]

    var body: some View {
        if images.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 104)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .topLeading) {
                                Text("\(index + 1)")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.thinMaterial, in: Capsule())
                                    .padding(5)
                            }
                    }
                }
            }
            .accessibilityLabel("\(images.count) selected screenshots")
        }
    }
}

#Preview {
    ContentView()
}
