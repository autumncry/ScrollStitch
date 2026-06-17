import UIKit

enum TestImageFactory {
    static func stripedImage(width: Int, rows: [UIColor], rowHeight: Int) -> UIImage {
        let size = CGSize(width: width, height: rows.count * rowHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            for (index, color) in rows.enumerated() {
                color.setFill()
                context.fill(CGRect(x: 0, y: index * rowHeight, width: width, height: rowHeight))
            }
        }
    }
}

extension UIImage {
    func hasStripeSequence(_ colors: [UIColor], rowHeight: Int) -> Bool {
        guard let cgImage else { return false }
        for (index, color) in colors.enumerated() {
            let y = index * rowHeight + rowHeight / 2
            guard cgImage.pixelColor(x: 4, y: y)?.isClose(to: color) == true else {
                return false
            }
        }
        return true
    }
}

private extension CGImage {
    func pixelColor(x: Int, y: Int) -> UIColor? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.translateBy(x: CGFloat(-x), y: CGFloat(y - height + 1))
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return UIColor(
            red: CGFloat(pixel[0]) / 255,
            green: CGFloat(pixel[1]) / 255,
            blue: CGFloat(pixel[2]) / 255,
            alpha: CGFloat(pixel[3]) / 255
        )
    }
}

private extension UIColor {
    func isClose(to other: UIColor, tolerance: CGFloat = 0.03) -> Bool {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return abs(r1 - r2) <= tolerance
            && abs(g1 - g2) <= tolerance
            && abs(b1 - b2) <= tolerance
            && abs(a1 - a2) <= tolerance
    }
}
