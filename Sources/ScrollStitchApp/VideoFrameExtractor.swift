import AVFoundation
import ScrollStitchCore
import UIKit

struct VideoFrameExtractor {
    func extractFrames(from url: URL, policy: VideoFrameSamplingPolicy) async throws -> [UIImage] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let times = policy.sampleTimes(duration: duration)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.08, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.08, preferredTimescale: 600)

        return try times.map { time in
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            let cgImage = try generator.copyCGImage(at: cmTime, actualTime: nil)
            return UIImage(cgImage: cgImage)
        }
    }
}
