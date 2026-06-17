import UIKit

public enum StitchingError: Error, Equatable {
    case emptyInput
    case imageRenderingFailed
    case incompatibleWidths(pairIndex: Int)
    case insufficientOverlap(pairIndex: Int)
}

public struct VerticalStitcher {
    public var minimumOverlap: Int
    public var maximumOverlap: Int
    public var mismatchThreshold: Double
    public var sampleStride: Int

    public init(
        minimumOverlap: Int = 16,
        maximumOverlap: Int = 420,
        mismatchThreshold: Double = 6,
        sampleStride: Int = 3
    ) {
        self.minimumOverlap = minimumOverlap
        self.maximumOverlap = maximumOverlap
        self.mismatchThreshold = mismatchThreshold
        self.sampleStride = max(1, sampleStride)
    }

    public func stitch(_ images: [UIImage]) throws -> UIImage {
        guard var stitched = images.first else {
            throw StitchingError.emptyInput
        }

        guard images.count > 1 else {
            return stitched
        }

        for (index, next) in images.dropFirst().enumerated() {
            let pairIndex = index
            let overlap = try bestOverlap(between: stitched, and: next, pairIndex: pairIndex)
            stitched = try render(stitched, followedBy: next, overlap: overlap)
        }

        return stitched
    }

    private func bestOverlap(between topImage: UIImage, and bottomImage: UIImage, pairIndex: Int) throws -> Int {
        let top = try ImageRaster(image: topImage)
        let bottom = try ImageRaster(image: bottomImage)

        guard top.width == bottom.width else {
            throw StitchingError.incompatibleWidths(pairIndex: pairIndex)
        }

        let largestOverlap = min(maximumOverlap, top.height, bottom.height)
        guard largestOverlap >= minimumOverlap else {
            throw StitchingError.insufficientOverlap(pairIndex: pairIndex)
        }

        var bestHeight = 0
        var bestScore = Double.greatestFiniteMagnitude

        for overlap in minimumOverlap...largestOverlap {
            let score = top.meanDifferenceToTop(of: bottom, overlap: overlap, stride: sampleStride)
            if score < bestScore {
                bestScore = score
                bestHeight = overlap
            }
        }

        guard bestScore <= mismatchThreshold else {
            throw StitchingError.insufficientOverlap(pairIndex: pairIndex)
        }

        return bestHeight
    }

    private func render(_ top: UIImage, followedBy bottom: UIImage, overlap: Int) throws -> UIImage {
        let width = max(top.size.width, bottom.size.width)
        let height = top.size.height + bottom.size.height - CGFloat(overlap)
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = top.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            top.draw(in: CGRect(origin: .zero, size: top.size))
            bottom.draw(in: CGRect(
                x: 0,
                y: top.size.height - CGFloat(overlap),
                width: bottom.size.width,
                height: bottom.size.height
            ))
        }
    }
}

private struct ImageRaster {
    let width: Int
    let height: Int
    let bytes: [UInt8]

    init(image: UIImage) throws {
        width = max(1, Int(image.size.width.rounded()))
        height = max(1, Int(image.size.height.rounded()))

        var data = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw StitchingError.imageRenderingFailed
        }

        guard let cgImage = image.cgImage else {
            throw StitchingError.imageRenderingFailed
        }

        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        bytes = data
    }

    func meanDifferenceToTop(of bottom: ImageRaster, overlap: Int, stride sampleStride: Int) -> Double {
        var total = 0
        var samples = 0

        for y in stride(from: 0, to: overlap, by: sampleStride) {
            let topY = height - overlap + y
            let bottomY = y

            for x in stride(from: 0, to: width, by: sampleStride) {
                let topOffset = byteOffset(x: x, visualY: topY)
                let bottomOffset = bottom.byteOffset(x: x, visualY: bottomY)

                total += abs(Int(bytes[topOffset]) - Int(bottom.bytes[bottomOffset]))
                total += abs(Int(bytes[topOffset + 1]) - Int(bottom.bytes[bottomOffset + 1]))
                total += abs(Int(bytes[topOffset + 2]) - Int(bottom.bytes[bottomOffset + 2]))
                samples += 3
            }
        }

        guard samples > 0 else {
            return Double.greatestFiniteMagnitude
        }

        return Double(total) / Double(samples)
    }

    private func byteOffset(x: Int, visualY: Int) -> Int {
        let storageY = height - 1 - visualY
        return ((storageY * width) + x) * 4
    }
}
