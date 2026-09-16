import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
#endif

class CropViewModel: ObservableObject {
    private let maskRadius: CGFloat
    private let maxMagnificationScale: CGFloat // The maximum allowed scale factor for image magnification.
    private var maskShape: MaskShape // The shape of the mask used for cropping.
    var rectAspectRatio: CGFloat // The aspect ratio for rectangular masks.
    private let minAspectRatio: CGFloat // The minimum allowed aspect ratio when resizing a rectangle mask.
    private let maxAspectRatio: CGFloat // The maximum allowed aspect ratio when resizing a rectangle mask.
    
    @Published var imageSizeInView: CGSize = .zero // The size of the image as displayed in the view.
    @Published var maskSize: CGSize = .zero // The size of the mask used for cropping. This is updated based on the mask shape and available space.
    @Published var scale: CGFloat = 1.0 // The current scale factor of the image.
    @Published var lastScale: CGFloat = 1.0 // The previous scale factor of the image.
    @Published var offset: CGSize = .zero // The current offset of the image.
    @Published var lastOffset: CGSize = .zero // The previous offset of the image.
    @Published var angle: Angle = Angle(degrees: 0) // The current rotation angle of the image.
    @Published var lastAngle: Angle = Angle(degrees: 0) // The previous rotation angle of the image.
    var lastMaskHeight: CGFloat = 0 // The mask height at the start of a resize gesture.
    var lastMaskWidth: CGFloat = 0 // The mask width at the start of a resize gesture.
    
    init(
        maskRadius: CGFloat,
        maxMagnificationScale: CGFloat,
        maskShape: MaskShape,
        rectAspectRatio: CGFloat,
        minAspectRatio: CGFloat,
        maxAspectRatio: CGFloat
    ) {
        self.maskRadius = maskRadius
        self.maxMagnificationScale = maxMagnificationScale
        self.maskShape = maskShape
        self.rectAspectRatio = rectAspectRatio
        let clampedMin = max(minAspectRatio, 0.01) // enforce a reasonable minimum aspect ratio to prevent extreme distortion
        self.minAspectRatio = clampedMin
        self.maxAspectRatio = max(maxAspectRatio, clampedMin) // if maxAspectRatio is less than minAspectRatio, set it to minAspectRatio to avoid invalid aspect ratio range
    }
    
    /**
     Updates the mask size based on the given size and mask shape.
     - Parameter size: The size to base the mask size calculations on.
     */
    private func updateMaskSize(for size: CGSize) {
        switch maskShape {
        case .circle, .square:
            let diameter = min(maskRadius * 2, min(size.width, size.height))
            maskSize = CGSize(width: diameter, height: diameter)
        case .rectangle:
            let height = min(maskRadius * 2, size.height, size.width / rectAspectRatio)
            maskSize = CGSize(width: height * rectAspectRatio, height: height)
        }
    }
    
    /**
     Updates the mask dimensions based on the size of the image in the view.
     - Parameter imageSizeInView: The size of the image as displayed in the view.
     */
    func updateMaskDimensions(for imageSizeInView: CGSize) {
        guard imageSizeInView.width > 0, imageSizeInView.height > 0,
              imageSizeInView != self.imageSizeInView else { return }
        self.imageSizeInView = imageSizeInView
        updateMaskSize(for: imageSizeInView)
        lastMaskHeight = maskSize.height
        lastMaskWidth = maskSize.width
        // Resizing a window changes the fitted image and the valid zoom/pan bounds.
        clampScaleToMask()
        let limits = calculateDragGestureMax()
        offset = CGSize(
            width: min(max(offset.width, -limits.x), limits.x),
            height: min(max(offset.height, -limits.y), limits.y)
        )
        lastOffset = offset
    }

    /// Changes only the centered mask, retaining the user's zoom, pan, and rotation.
    /// Near an image edge, reduce the mask rather than moving or zooming the image.
    func updateMaskShape(_ shape: MaskShape, aspectRatio: CGFloat) {
        maskShape = shape
        rectAspectRatio = max(0.01, aspectRatio)
        guard imageSizeInView.width > 0, imageSizeInView.height > 0 else { return }
        let ratio: CGFloat = shape == .rectangle ? rectAspectRatio : 1
        let height = maskSize.height
        maskSize = CGSize(width: height * ratio, height: height)
        let availableWidth = max(0, imageSizeInView.width * scale - 2 * abs(offset.width))
        let availableHeight = max(0, imageSizeInView.height * scale - 2 * abs(offset.height))
        let fit = min(1, availableWidth / maskSize.width, availableHeight / maskSize.height)
        maskSize = CGSize(width: maskSize.width * fit, height: maskSize.height * fit)
        lastMaskWidth = maskSize.width
        lastMaskHeight = maskSize.height
    }

    /**
     Adjusts the mask height by `delta` symmetrically, clamped by view bounds and aspect ratio limits.
     - Parameter delta: The change in height (positive = taller).
     */
    func resizeMaskByHeightDelta(_ delta: CGFloat) {
        let desired = lastMaskHeight + delta
        let maxH = min(imageSizeInView.height, maskSize.width / minAspectRatio)
        let minH = max(50, maskSize.width / maxAspectRatio)
        let clamped = min(max(desired, minH), maxH)
        maskSize = CGSize(width: maskSize.width, height: clamped)
        rectAspectRatio = maskSize.width / clamped
        clampScaleToMask()
    }

    /**
     Adjusts the mask width by `delta` symmetrically, clamped by view bounds and aspect ratio limits.
     - Parameter delta: The change in width (positive = wider).
     */
    func resizeMaskByWidthDelta(_ delta: CGFloat) {
        let desired = lastMaskWidth + delta
        let maxW = min(imageSizeInView.width, maskSize.height * maxAspectRatio)
        let minW = max(50, maskSize.height * minAspectRatio)
        let clamped = min(max(desired, minW), maxW)
        maskSize = CGSize(width: clamped, height: maskSize.height)
        rectAspectRatio = clamped / maskSize.height
        clampScaleToMask()
    }

    /**
     Clamps the current scale into the range that is valid for the current mask size.
     Growing the mask raises the minimum scale, so the image has to catch up to keep filling the mask.
     */
    private func clampScaleToMask() {
        guard imageSizeInView.width > 0, imageSizeInView.height > 0 else { return }
        let maxScaleValues = calculateMagnificationGestureMaxValues()
        let clamped = min(max(scale, maxScaleValues.0), maxScaleValues.1)
        guard clamped != scale else { return }
        scale = clamped
        lastScale = clamped
    }
    
    /**
     Calculates the maximum allowed offset for dragging the image.
     - Returns: A CGPoint representing the maximum x and y offsets.
     */
    func calculateDragGestureMax() -> CGPoint {
        let xLimit = max(0, ((imageSizeInView.width / 2) * scale) - (maskSize.width / 2))
        let yLimit = max(0, ((imageSizeInView.height / 2) * scale) - (maskSize.height / 2))
        return CGPoint(x: xLimit, y: yLimit)
    }
    
    /**
     Calculates the minimum and maximum allowed scale values for image magnification.
     - Returns: A tuple containing the minimum and maximum scale values.
     */
    func calculateMagnificationGestureMaxValues() -> (CGFloat, CGFloat) {
        let minScale = max(maskSize.width / imageSizeInView.width, maskSize.height / imageSizeInView.height)
        return (minScale, maxMagnificationScale)
    }
    
    /// A fixed step based on minimum zoom, not the current zoom level.
    func zoomButtonScaleStep(fraction: CGFloat) -> CGFloat {
        guard imageSizeInView.width > 0, imageSizeInView.height > 0 else { return 0 }
        return calculateMagnificationGestureMaxValues().0 * max(0, fraction)
    }

    /**
     Crops the given image to a rectangle based on the current mask size and position.
     - Parameter image: The PlatformImage to crop.
     - Returns: A cropped PlatformImage, or nil if cropping fails.
     */
    func cropToRectangle(_ image: PlatformImage) -> PlatformImage? {
        guard let orientedImage = image.correctlyOriented else { return nil }
        return cropBitmap(of: orientedImage, to: calculateCropRect(orientedImage))
    }

    /**
     Crops the given image to a square based on the current mask size and position.
     - Parameter image: The PlatformImage to crop.
     - Returns: A cropped PlatformImage, or nil if cropping fails.
     */
    func cropToSquare(_ image: PlatformImage) -> PlatformImage? {
        guard let orientedImage = image.correctlyOriented else { return nil }
        return cropBitmap(of: orientedImage, to: calculateCropRect(orientedImage))
    }

    /**
     Crops the bitmap backing the given image to the given area.
     - Parameter orientedImage: The correctly oriented PlatformImage to crop.
     - Parameter cropRect: The area to keep, in the image's point coordinate space.
     - Returns: A cropped PlatformImage, or nil if cropping fails.
     */
    private func cropBitmap(of orientedImage: PlatformImage, to cropRect: CGRect) -> PlatformImage? {
        #if canImport(UIKit)
        guard let cgImage = orientedImage.cgImage,
              let result = cgImage.cropping(to: cropRect.inPixels(of: cgImage, pointSize: orientedImage.size)) else {
            return nil
        }
        return UIImage(cgImage: result, scale: orientedImage.scale, orientation: .up)
        #elseif canImport(AppKit)
        guard let cgImage = orientedImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let croppedCGImage = cgImage.cropping(to: cropRect.inPixels(of: cgImage, pointSize: orientedImage.size)) else {
            return nil
        }
        return NSImage(cgImage: croppedCGImage, size: cropRect.size)
        #endif
    }

    /**
     Crops the given image to a circle based on the current mask size and position.
     - Parameter image: The PlatformImage to crop.
     - Returns: A cropped PlatformImage, or nil if cropping fails.
     */
    func cropToCircle(_ image: PlatformImage) -> PlatformImage? {
        guard let orientedImage = image.correctlyOriented else { return nil }

        let cropRect = calculateCropRect(orientedImage)

        #if canImport(UIKit)
        let imageRendererFormat = orientedImage.imageRendererFormat
        imageRendererFormat.opaque = false

        let circleCroppedImage = UIGraphicsImageRenderer(
            size: cropRect.size,
            format: imageRendererFormat).image { _ in
                let drawRect = CGRect(origin: .zero, size: cropRect.size)
                UIBezierPath(ovalIn: drawRect).addClip()
                let drawImageRect = CGRect(
                    origin: CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y),
                    size: orientedImage.size
                )
                orientedImage.draw(in: drawImageRect)
            }

        return circleCroppedImage
        #elseif canImport(AppKit)
        let circleCroppedImage = NSImage(size: cropRect.size)
        circleCroppedImage.lockFocus()
        let drawRect = NSRect(origin: .zero, size: cropRect.size)
        NSBezierPath(ovalIn: drawRect).addClip()
        let drawImageRect = NSRect(
            origin: NSPoint(x: -cropRect.origin.x, y: -cropRect.origin.y),
            size: orientedImage.size
        )
        orientedImage.draw(in: drawImageRect)
        circleCroppedImage.unlockFocus()
        return circleCroppedImage
        #endif
    }
    
    /**
     Rotates the given image by the specified angle.
     - Parameter image: The PlatformImage to rotate.
     - Parameter angle: The Angle to rotate the image by.
     - Returns: A rotated PlatformImage, or nil if rotation fails.
     */
    func rotate(_ image: PlatformImage, _ angle: Angle) -> PlatformImage? {
        guard let orientedImage = image.correctlyOriented else { return nil }

        #if canImport(UIKit)
        guard let cgImage = orientedImage.cgImage else { return nil }
        #elseif canImport(AppKit)
        guard let cgImage = orientedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #endif

        let ciImage = CIImage(cgImage: cgImage)

        guard let filter = CIFilter.straightenFilter(image: ciImage, radians: angle.radians),
              let output = filter.outputImage else { return nil }

        let context = CIContext()
        guard let result = context.createCGImage(output, from: output.extent) else { return nil }

        #if canImport(UIKit)
        return UIImage(cgImage: result)
        #elseif canImport(AppKit)
        return NSImage(cgImage: result, size: NSSize(width: result.width, height: result.height))
        #endif
    }
    
    /**
     Calculates the rectangle to use for cropping the image based on the current mask size, scale, and offset.
     - Parameter orientedImage: The correctly oriented PlatformImage to calculate the crop rect for.
     - Returns: A CGRect representing the area to crop from the original image.
     */
    private func calculateCropRect(_ orientedImage: PlatformImage) -> CGRect {
        let factor = min(
            (orientedImage.size.width / imageSizeInView.width),
            (orientedImage.size.height / imageSizeInView.height)
        )
        let centerInOriginalImage = CGPoint(
            x: orientedImage.size.width / 2,
            y: orientedImage.size.height / 2
        )
        
        let cropSizeInOriginalImage = CGSize(
            width: (maskSize.width * factor) / scale,
            height: (maskSize.height * factor) / scale
        )
        
        let offsetX = offset.width * factor / scale
        let offsetY = offset.height * factor / scale
        
        let cropRectX = (centerInOriginalImage.x - cropSizeInOriginalImage.width / 2) - offsetX
        let cropRectY = (centerInOriginalImage.y - cropSizeInOriginalImage.height / 2) - offsetY
        
        return CGRect(
            origin: CGPoint(x: cropRectX, y: cropRectY),
            size: cropSizeInOriginalImage
        )
    }
}

extension PlatformImage {
    /**
     A PlatformImage instance with corrected orientation.
     For UIImage, if the instance's orientation is already `.up`, it simply returns the original.
     For NSImage, it returns self as macOS doesn't have orientation issues.
     - Returns: An optional PlatformImage that represents the correctly oriented image.
     */
    var correctlyOriented: PlatformImage? {
        #if canImport(UIKit)
        if imageOrientation == .up { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage
        #elseif canImport(AppKit)
        return self
        #endif
    }
}

private extension CGRect {
    /**
     Converts a rect measured in an image's point coordinate space into the pixel coordinate space of
     its bitmap, which is the space `CGImage.cropping(to:)` works in.

     The two are not the same. On macOS `NSImage.size` is derived from the file's DPI metadata, so a
     96 dpi image reports 0.75x its pixel dimensions. On iOS `UIImage.size` is the pixel size divided
     by `scale`. Cropping a point sized rect out of the bitmap would keep too small an area, offset
     towards the top left corner.
     - Parameter cgImage: The bitmap the resulting rect is measured against.
     - Parameter pointSize: The size of the image in points, as laid out on screen.
     - Returns: The equivalent rect in pixels.
     */
    func inPixels(of cgImage: CGImage, pointSize: CGSize) -> CGRect {
        guard pointSize.width > 0, pointSize.height > 0 else { return self }
        let scaleX = CGFloat(cgImage.width) / pointSize.width
        let scaleY = CGFloat(cgImage.height) / pointSize.height
        return CGRect(
            x: origin.x * scaleX,
            y: origin.y * scaleY,
            width: size.width * scaleX,
            height: size.height * scaleY
        )
    }
}

private extension CIFilter {
    /**
     Creates the straighten filter.
     - Parameters:
     - inputImage: The CIImage to use as an input image
     - radians: An angle in radians
     - Returns: A generated CIFilter.
     */
    static func straightenFilter(image: CIImage, radians: Double) -> CIFilter? {
        let angle: Double = radians != 0 ? -radians : 0
        guard let filter = CIFilter(name: "CIStraightenFilter") else {
            return nil
        }
        filter.setDefaults()
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(angle, forKey: kCIInputAngleKey)
        return filter
    }
}
