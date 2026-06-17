import XCTest
import UIKit
@testable import ScrollStitchCore

final class VerticalStitcherTests: XCTestCase {
    func testStitchesTwoImagesByRemovingDuplicatedOverlap() throws {
        let top = TestImageFactory.stripedImage(
            width: 24,
            rows: [.red, .green, .blue, .yellow],
            rowHeight: 10
        )
        let bottom = TestImageFactory.stripedImage(
            width: 24,
            rows: [.blue, .yellow, .purple, .orange],
            rowHeight: 10
        )

        let result = try VerticalStitcher().stitch([top, bottom])

        XCTAssertEqual(result.size.width, 24)
        XCTAssertEqual(result.size.height, 60)
        XCTAssertTrue(result.hasStripeSequence([UIColor.red, .green, .blue, .yellow, .purple, .orange], rowHeight: 10))
    }

    func testThrowsWhenImagesDoNotOverlapEnough() {
        let top = TestImageFactory.stripedImage(width: 24, rows: [.red, .green, .blue], rowHeight: 10)
        let bottom = TestImageFactory.stripedImage(width: 24, rows: [.yellow, .purple, .orange], rowHeight: 10)

        XCTAssertThrowsError(try VerticalStitcher(minimumOverlap: 8).stitch([top, bottom])) { error in
            XCTAssertEqual(error as? StitchingError, .insufficientOverlap(pairIndex: 0))
        }
    }
}
