import CoreGraphics

public enum PageCapturePlanError: Error, Equatable {
    case invalidDimensions
    case stalled
}

public struct PageCaptureSlice: Equatable {
    public let contentOffsetY: CGFloat
    public let sourceY: CGFloat
    public let drawY: CGFloat
    public let height: CGFloat

    public init(contentOffsetY: CGFloat, sourceY: CGFloat, drawY: CGFloat, height: CGFloat) {
        self.contentOffsetY = contentOffsetY
        self.sourceY = sourceY
        self.drawY = drawY
        self.height = height
    }
}

public enum PageCapturePlan {
    public static func slices(contentHeight: CGFloat, viewportHeight: CGFloat) throws -> [PageCaptureSlice] {
        guard contentHeight > 0, viewportHeight > 0 else {
            throw PageCapturePlanError.invalidDimensions
        }

        let maxOffset = max(0, contentHeight - viewportHeight)
        var slices: [PageCaptureSlice] = []
        var nextUnfilledY: CGFloat = 0

        while nextUnfilledY < contentHeight {
            let contentOffsetY = min(nextUnfilledY, maxOffset)
            let sourceY = nextUnfilledY - contentOffsetY
            let visibleRemainder = viewportHeight - sourceY
            let height = min(visibleRemainder, contentHeight - nextUnfilledY)

            guard height > 0 else {
                throw PageCapturePlanError.stalled
            }

            slices.append(PageCaptureSlice(
                contentOffsetY: contentOffsetY,
                sourceY: sourceY,
                drawY: nextUnfilledY,
                height: height
            ))

            nextUnfilledY += height
        }

        return slices
    }
}
