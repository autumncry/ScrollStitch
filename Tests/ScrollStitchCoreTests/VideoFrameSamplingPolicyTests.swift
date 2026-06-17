import XCTest
@testable import ScrollStitchCore

final class VideoFrameSamplingPolicyTests: XCTestCase {
    func testSamplesDurationAtIntervalAndRespectsMaximumFrameCount() {
        let policy = VideoFrameSamplingPolicy(interval: 0.5, maximumFrameCount: 5)

        XCTAssertEqual(policy.sampleTimes(duration: 3.2), [0, 0.5, 1.0, 1.5, 2.0])
    }

    func testAlwaysIncludesFirstFrameForShortVideos() {
        let policy = VideoFrameSamplingPolicy(interval: 1.0, maximumFrameCount: 8)

        XCTAssertEqual(policy.sampleTimes(duration: 0.2), [0])
    }
}
