import XCTest
import SwiftUI
@testable import SwiftyCrop

final class SwiftyCropTests: XCTestCase {
  func testConfigurationInit() {
    let configuration = SwiftyCropConfiguration(
      maxMagnificationScale: 1.0,
      maskRadius: 1.0,
      cropImageCircular: true,
      rotateImage: true,
      rotateImageWithButtons: true,
      showsZoomSlider: true,
      zoomSensitivity: 2,
      rectAspectRatio: 4/3,
      dismissesOnCompletion: false,
      showsProgressLayer: false,
      progressLayerDelay: .milliseconds(200),
      texts: SwiftyCropConfiguration.Texts(
        cancelButton: "Test 1",
        interactionInstructions: "Test 2",
        saveButton: "Test 3",
        zoomSliderLabel: "Test 4"
      ),
      fonts: SwiftyCropConfiguration.Fonts(
        cancelButton: Font.system(size: 12),
        interactionInstructions: Font.system(size: 13),
        saveButton: Font.system(size: 14)
      ),
      colors: SwiftyCropConfiguration.Colors(
        cancelButton: .red,
        interactionInstructions: .yellow,
        saveButton: .green,
        background: .gray,
        zoomSlider: .orange
      )
    )
    
    XCTAssertEqual(configuration.maxMagnificationScale, 1.0)
    XCTAssertEqual(configuration.maskRadius, 1.0)
    XCTAssertEqual(configuration.cropImageCircular, true)
    XCTAssertEqual(configuration.rotateImage, true)
    XCTAssertEqual(configuration.rotateImageWithButtons, true)
    XCTAssertEqual(configuration.showsZoomSlider, true)
    XCTAssertEqual(configuration.zoomSensitivity, 2)
    XCTAssertEqual(configuration.rectAspectRatio, 4/3)
    XCTAssertEqual(configuration.dismissesOnCompletion, false)
    XCTAssertEqual(configuration.showsProgressLayer, false)
    XCTAssertEqual(configuration.progressLayerDelay, .milliseconds(200))

    XCTAssertEqual(configuration.texts.cancelButton, "Test 1")
    XCTAssertEqual(configuration.texts.interactionInstructions, "Test 2")
    XCTAssertEqual(configuration.texts.saveButton, "Test 3")
    XCTAssertEqual(configuration.texts.zoomSliderLabel, "Test 4")

    XCTAssertEqual(configuration.fonts.cancelButton, Font.system(size: 12))
    XCTAssertEqual(configuration.fonts.interactionInstructions, Font.system(size: 13))
    XCTAssertEqual(configuration.fonts.saveButton, Font.system(size: 14))
    
    XCTAssertEqual(configuration.colors.cancelButton, Color.red)
    XCTAssertEqual(configuration.colors.interactionInstructions, Color.yellow)
    XCTAssertEqual(configuration.colors.saveButton, Color.green)
    XCTAssertEqual(configuration.colors.background, Color.gray)
    XCTAssertEqual(configuration.colors.zoomSlider, Color.orange)
  }

  func testDismissesOnCompletionDefault() {
    let configuration = SwiftyCropConfiguration()

    XCTAssertEqual(configuration.dismissesOnCompletion, true)
    XCTAssertEqual(configuration.showsProgressLayer, true)
    XCTAssertEqual(configuration.progressLayerDelay, .zero)
  }

  func testZoomSliderDefaults() {
    let configuration = SwiftyCropConfiguration()

    XCTAssertEqual(configuration.showsZoomSlider, false)
    XCTAssertNil(configuration.texts.zoomSliderLabel)
    XCTAssertEqual(configuration.colors.zoomSlider, Color.white)
  }
}
