import XCTest
import ImageIO
import UniformTypeIdentifiers
@testable import SwiftyCrop

/// Regression tests for the mapping between an image's point coordinate space (`PlatformImage.size`)
/// and the pixel coordinate space of its `CGImage`, which is what `CGImage.cropping(to:)` operates on.
///
/// The two are not the same. On macOS `NSImage.size` is derived from the file's DPI metadata, so a
/// 96 dpi image reports 0.75x its pixel dimensions. On iOS `UIImage.size` is the pixel size divided
/// by `scale`. Measuring the crop in points and then applying it to the bitmap yields a crop that is
/// both too small and offset towards the top left corner.
final class CropGeometryTests: XCTestCase {
  func testSquareCropIsCentredWhenPointSizeDiffersFromPixelSize() throws {
    // 800x600 pixels at 144 dpi: the image reports 400x300 points, the bitmap stays 800x600.
    let image = try XCTUnwrap(Self.makeSplitImage(pixelsWide: 800, pixelsHigh: 600, dpi: 144))
    let viewModel = Self.makeViewModel()

    // The crop view lays the image out and measures the result, so the view size is in points.
    viewModel.updateMaskDimensions(for: image.size)

    let cropped = try XCTUnwrap(viewModel.cropToSquare(image))
    let bitmap = try XCTUnwrap(Self.cgImage(of: cropped))

    // The source is black left of its centre and white right of it. Nothing was dragged or zoomed,
    // so a correct crop is centred on the image and has to straddle that edge.
    XCTAssertEqual(
      Self.brightness(of: bitmap, atRelativeX: 0.25), 0, accuracy: 0.02,
      "left half of the crop should fall in the black half of the source"
    )
    XCTAssertEqual(
      Self.brightness(of: bitmap, atRelativeX: 0.75), 1, accuracy: 0.02,
      "right half of the crop should fall in the white half of the source"
    )
  }

  func testCropResolutionMatchesTheSelectedAreaInPixels() throws {
    let image = try XCTUnwrap(Self.makeSplitImage(pixelsWide: 800, pixelsHigh: 600, dpi: 144))
    let viewModel = Self.makeViewModel()
    viewModel.updateMaskDimensions(for: image.size)

    let cropped = try XCTUnwrap(viewModel.cropToSquare(image))
    let bitmap = try XCTUnwrap(Self.cgImage(of: cropped))

    // The mask covers `maskSize` of an image laid out at `image.size` points, and the bitmap behind
    // those points is 800 pixels wide, so that fraction of 800 pixels has to survive the crop.
    let pointsToPixels = 800 / image.size.width
    let expected = viewModel.maskSize.width * pointsToPixels
    XCTAssertEqual(CGFloat(bitmap.width), expected, accuracy: 1)
    XCTAssertEqual(CGFloat(bitmap.height), expected, accuracy: 1)
  }

  func testDraggingTheImageMovesTheCropByTheSameAmount() throws {
    let image = try XCTUnwrap(Self.makeSplitImage(pixelsWide: 800, pixelsHigh: 600, dpi: 144))
    let viewModel = Self.makeViewModel()
    viewModel.updateMaskDimensions(for: image.size)

    // Drag the image 70 points to the left, which is the maximum the mask allows here.
    XCTAssertEqual(viewModel.calculateDragGestureMax().x, 70, accuracy: 0.001)
    viewModel.offset = CGSize(width: -70, height: 0)

    let cropped = try XCTUnwrap(viewModel.cropToSquare(image))
    let bitmap = try XCTUnwrap(Self.cgImage(of: cropped))

    // In points the crop starts at 200 (centre) - 130 (half mask) + 70 (drag) = 140, so at pixel 280
    // and 520 pixels wide. The black/white seam sits at pixel 400, i.e. 23% into the crop.
    XCTAssertEqual(Self.seamRelativeX(of: bitmap), (400 - 280) / 520, accuracy: 0.01)
  }

  func testCircularCropIsCentredToo() throws {
    let image = try XCTUnwrap(Self.makeSplitImage(pixelsWide: 800, pixelsHigh: 600, dpi: 144))
    let viewModel = Self.makeViewModel()
    viewModel.updateMaskDimensions(for: image.size)

    let cropped = try XCTUnwrap(viewModel.cropToCircle(image))
    let bitmap = try XCTUnwrap(Self.cgImage(of: cropped))

    // The circle path renders in point space rather than cropping the bitmap, so it was never
    // affected by the point/pixel mismatch. This pins that down.
    XCTAssertEqual(Self.seamRelativeX(of: bitmap), 0.5, accuracy: 0.02)
  }

  func testWindowShrinkClampsZoomAndPanToTheNewImageBounds() {
    let viewModel = Self.makeViewModel()
    viewModel.updateMaskDimensions(for: CGSize(width: 600, height: 1200))
    viewModel.scale = 0.5
    viewModel.lastScale = 0.5
    viewModel.offset = CGSize(width: 20, height: 170)

    viewModel.updateMaskDimensions(for: CGSize(width: 200, height: 400))

    XCTAssertEqual(viewModel.maskSize, CGSize(width: 200, height: 200))
    XCTAssertEqual(viewModel.scale, 1)
    XCTAssertEqual(viewModel.lastScale, 1)
    XCTAssertEqual(viewModel.offset, CGSize(width: 0, height: 100))
    XCTAssertEqual(viewModel.lastOffset, viewModel.offset)
  }

  func testTransientZeroLayoutDoesNotInvalidateCropGeometry() {
    let viewModel = Self.makeViewModel()
    viewModel.updateMaskDimensions(for: CGSize(width: 300, height: 600))
    viewModel.updateMaskDimensions(for: .zero)

    XCTAssertEqual(viewModel.imageSizeInView, CGSize(width: 300, height: 600))
    XCTAssertEqual(viewModel.maskSize, CGSize(width: 260, height: 260))
    XCTAssertTrue(viewModel.calculateMagnificationGestureMaxValues().0.isFinite)
  }

  func testCropAfterWindowResizeMatchesCurrentViewport() throws {
    let image = try XCTUnwrap(Self.makeSplitImage(pixelsWide: 800, pixelsHigh: 600, dpi: 144))
    let viewModel = Self.makeViewModel()
    viewModel.updateMaskDimensions(for: CGSize(width: 800, height: 600))
    viewModel.updateMaskDimensions(for: CGSize(width: 200, height: 150))

    let cropped = try XCTUnwrap(viewModel.cropToSquare(image))
    let bitmap = try XCTUnwrap(Self.cgImage(of: cropped))
    XCTAssertEqual(bitmap.width, 600)
    XCTAssertEqual(bitmap.height, 600)
    XCTAssertEqual(Self.seamRelativeX(of: bitmap), 0.5, accuracy: 0.01)
  }

  // MARK: - Helpers

  private static func makeViewModel() -> CropViewModel {
    CropViewModel(
      maskRadius: 130,
      maxMagnificationScale: 4,
      maskShape: .square,
      rectAspectRatio: 1,
      minAspectRatio: 0.1,
      maxAspectRatio: 10
    )
  }

  /// An image that is black in its left half and white in its right half, tagged with `dpi`.
  private static func makeSplitImage(pixelsWide: Int, pixelsHigh: Int, dpi: CGFloat) -> PlatformImage? {
    guard let context = CGContext(
      data: nil,
      width: pixelsWide,
      height: pixelsHigh,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return nil }

    context.setFillColor(gray: 0, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: pixelsWide / 2, height: pixelsHigh))
    context.setFillColor(gray: 1, alpha: 1)
    context.fill(CGRect(x: pixelsWide / 2, y: 0, width: pixelsWide - pixelsWide / 2, height: pixelsHigh))

    guard let cgImage = context.makeImage() else { return nil }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
      data, UTType.png.identifier as CFString, 1, nil
    ) else { return nil }
    CGImageDestinationAddImage(
      destination,
      cgImage,
      [kCGImagePropertyDPIWidth: dpi, kCGImagePropertyDPIHeight: dpi] as CFDictionary
    )
    guard CGImageDestinationFinalize(destination) else { return nil }

    #if canImport(UIKit)
    // `UIImage(data:)` ignores the DPI tag and always reports scale 1, which would make points and
    // pixels identical and defeat the point of these tests. Pass the equivalent scale explicitly so
    // both platforms end up with the same point size for the same bitmap.
    return PlatformImage(data: data as Data, scale: dpi / 72)
    #elseif canImport(AppKit)
    return PlatformImage(data: data as Data)
    #endif
  }

  private static func cgImage(of image: PlatformImage) -> CGImage? {
    #if canImport(UIKit)
    return image.cgImage
    #elseif canImport(AppKit)
    return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    #endif
  }

  /// The brightness of the pixel at `atRelativeX` (0...1) on the image's horizontal centre line.
  private static func brightness(of cgImage: CGImage, atRelativeX relativeX: CGFloat) -> CGFloat {
    let row = centreRow(of: cgImage)
    let x = min(row.count - 1, max(0, Int(CGFloat(row.count) * relativeX)))
    return row[x]
  }

  /// Where the source image's black/white seam ends up within the crop, as a fraction of its width.
  private static func seamRelativeX(of cgImage: CGImage) -> CGFloat {
    let row = centreRow(of: cgImage)
    guard let seam = row.firstIndex(where: { $0 > 0.5 }) else { return .nan }
    return CGFloat(seam) / CGFloat(row.count)
  }

  /// The brightness of every pixel on the image's horizontal centre line.
  private static func centreRow(of cgImage: CGImage) -> [CGFloat] {
    let width = cgImage.width
    let height = cgImage.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)

    pixels.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
      context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    }

    let y = height / 2
    return (0..<width).map { CGFloat(pixels[(y * width + $0) * 4]) / 255 }
  }
}
