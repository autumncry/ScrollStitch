import CoreGraphics
import XCTest
@testable import ScrollStitchCore

final class PageCapturePlanTests: XCTestCase {
    func testCreatesSingleCroppedSliceForPageShorterThanViewport() throws {
        let slices = try PageCapturePlan.slices(contentHeight: 700, viewportHeight: 1_000)

        XCTAssertEqual(slices, [
            PageCaptureSlice(contentOffsetY: 0, sourceY: 0, drawY: 0, height: 700)
        ])
    }

    func testCreatesSequentialSlicesForExactViewportPages() throws {
        let slices = try PageCapturePlan.slices(contentHeight: 2_000, viewportHeight: 1_000)

        XCTAssertEqual(slices, [
            PageCaptureSlice(contentOffsetY: 0, sourceY: 0, drawY: 0, height: 1_000),
            PageCaptureSlice(contentOffsetY: 1_000, sourceY: 0, drawY: 1_000, height: 1_000)
        ])
    }

    func testCropsFinalSliceWhenViewportCannotScrollToNextUnfilledRow() throws {
        let slices = try PageCapturePlan.slices(contentHeight: 2_100, viewportHeight: 1_000)

        XCTAssertEqual(slices, [
            PageCaptureSlice(contentOffsetY: 0, sourceY: 0, drawY: 0, height: 1_000),
            PageCaptureSlice(contentOffsetY: 1_000, sourceY: 0, drawY: 1_000, height: 1_000),
            PageCaptureSlice(contentOffsetY: 1_100, sourceY: 900, drawY: 2_000, height: 100)
        ])
    }

    func testRejectsInvalidDimensions() {
        XCTAssertThrowsError(try PageCapturePlan.slices(contentHeight: 0, viewportHeight: 1_000)) { error in
            XCTAssertEqual(error as? PageCapturePlanError, .invalidDimensions)
        }
        XCTAssertThrowsError(try PageCapturePlan.slices(contentHeight: 1_000, viewportHeight: 0)) { error in
            XCTAssertEqual(error as? PageCapturePlanError, .invalidDimensions)
        }
    }
}
