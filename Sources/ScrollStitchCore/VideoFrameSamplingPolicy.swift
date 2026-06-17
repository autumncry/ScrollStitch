import Foundation

public struct VideoFrameSamplingPolicy {
    public var interval: TimeInterval
    public var maximumFrameCount: Int

    public init(interval: TimeInterval = 0.45, maximumFrameCount: Int = 60) {
        self.interval = max(0.1, interval)
        self.maximumFrameCount = max(1, maximumFrameCount)
    }

    public func sampleTimes(duration: TimeInterval) -> [TimeInterval] {
        guard duration > 0 else {
            return [0]
        }

        var times: [TimeInterval] = []
        var current: TimeInterval = 0

        while current <= duration, times.count < maximumFrameCount {
            times.append(round(current * 1000) / 1000)
            current += interval
        }

        if times.isEmpty {
            return [0]
        }

        return times
    }
}
