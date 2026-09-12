import XCTest
import SwiftUI
@testable import SwiftyCrop

final class MaskSwitchingTests: XCTestCase {
    func testChangingShapePreservesZoomPanAndRotation() {
        let model = makeModel()
        model.updateMaskDimensions(for: CGSize(width: 400, height: 600))
        model.scale = 1.8
        model.lastScale = 1.8
        model.offset = CGSize(width: 37, height: -64)
        model.lastOffset = model.offset
        model.angle = .degrees(12)
        model.lastAngle = model.angle

        for (shape, ratio) in [(MaskShape.rectangle, 1.25), (.rectangle, 1), (.circle, 1)] {
            model.updateMaskShape(shape, aspectRatio: ratio)
            XCTAssertEqual(model.scale, 1.8)
            XCTAssertEqual(model.lastScale, 1.8)
            XCTAssertEqual(model.offset, CGSize(width: 37, height: -64))
            XCTAssertEqual(model.lastOffset, model.offset)
            XCTAssertEqual(model.angle.degrees, 12, accuracy: 0.000001)
            XCTAssertEqual(model.lastAngle, model.angle)
            XCTAssertEqual(model.maskSize.width / model.maskSize.height, ratio, accuracy: 0.001)
        }
    }

    func testGrowingMaskNearEdgeShrinksMaskInsteadOfMovingImage() {
        let model = makeModel()
        model.updateMaskDimensions(for: CGSize(width: 400, height: 400))
        model.updateMaskShape(.rectangle, aspectRatio: 1.25)
        model.offset = CGSize(width: 0, height: 95)
        model.lastOffset = model.offset
        model.updateMaskShape(.circle, aspectRatio: 1)

        XCTAssertEqual(model.scale, 1)
        XCTAssertEqual(model.offset.height, 95)
        XCTAssertEqual(model.maskSize.width, model.maskSize.height)
        XCTAssertLessThanOrEqual(model.maskSize.height / 2 + abs(model.offset.height), 200)
    }

    func testCircleToWideRectanglePreservesHeight() {
        let model = makeModel()
        model.updateMaskDimensions(for: CGSize(width: 500, height: 500))
        let height = model.maskSize.height
        model.updateMaskShape(.rectangle, aspectRatio: 1.25)
        XCTAssertEqual(model.maskSize.height, height)
        XCTAssertEqual(model.maskSize.width, height * 1.25)
        model.updateMaskShape(.rectangle, aspectRatio: 1)
        XCTAssertEqual(model.maskSize.height, height)
        XCTAssertEqual(model.maskSize.width, height)
        model.updateMaskShape(.rectangle, aspectRatio: 1.25)
        XCTAssertEqual(model.maskSize.height, height)
        XCTAssertEqual(model.maskSize.width, height * 1.25)
    }

    func testZoomStepUsesMinimumScaleRatherThanCurrentScale() {
        let model = makeModel()
        model.updateMaskDimensions(for: CGSize(width: 400, height: 600))
        let step = model.zoomButtonScaleStep(fraction: 0.05)
        XCTAssertEqual(step, (260.0 / 400.0) * 0.05, accuracy: 0.000001)
        model.scale = 3
        XCTAssertEqual(model.zoomButtonScaleStep(fraction: 0.05), step)
        XCTAssertEqual(model.zoomButtonScaleStep(fraction: 0.1), step * 2)
    }

    private func makeModel() -> CropViewModel {
        CropViewModel(maskRadius: 130, maxMagnificationScale: 4, maskShape: .circle,
                      rectAspectRatio: 1, minAspectRatio: 0.1, maxAspectRatio: 10)
    }
}
