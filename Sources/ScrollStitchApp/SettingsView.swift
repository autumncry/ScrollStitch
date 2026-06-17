import SwiftUI

struct SettingsView: View {
    @ObservedObject var workspace: StitchWorkspace
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Screenshot Stitching") {
                    SliderRow(
                        title: "Minimum overlap",
                        value: $workspace.minimumOverlap,
                        range: 8...160,
                        step: 1,
                        unit: "px"
                    )
                    SliderRow(
                        title: "Maximum overlap",
                        value: $workspace.maximumOverlap,
                        range: 120...900,
                        step: 10,
                        unit: "px"
                    )
                    SliderRow(
                        title: "Match tolerance",
                        value: $workspace.mismatchThreshold,
                        range: 2...40,
                        step: 1,
                        unit: ""
                    )
                }

                Section("Recording Frames") {
                    SliderRow(
                        title: "Frame interval",
                        value: $workspace.frameInterval,
                        range: 0.25...1.2,
                        step: 0.05,
                        unit: "s"
                    )
                    SliderRow(
                        title: "Maximum frames",
                        value: $workspace.maximumFrameCount,
                        range: 12...120,
                        step: 1,
                        unit: ""
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(formattedValue)
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }

    private var formattedValue: String {
        if unit == "s" {
            return String(format: "%.2f%@", value, unit)
        }
        return "\(Int(value.rounded()))\(unit)"
    }
}
