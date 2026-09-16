import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// `SwiftyCropView` is a SwiftUI view for cropping images.
///
/// You can customize the cropping behavior using a `SwiftyCropConfiguration` instance and a completion handler.
///
/// - Parameters:
///   - imageToCrop: The image to be cropped.
///   - maskShape: The shape of the mask used for cropping.
///   - topAccessory: Optional controls placed below the navigation toolbar, inside the safe area.
///   - configuration: The configuration for the cropping behavior. If nothing is specified, the default is used.
///   - onCancel: An optional closure that's called when the cropping is cancelled.
///   - onComplete: A closure that's called when the cropping is complete. This closure returns the cropped image.
///     If an error occurs the return value is nil.
public struct SwiftyCropView: View {
    private let topAccessory: AnyView?
    private let maskShape: MaskShape
    private let configuration: SwiftyCropConfiguration
    private let onCancel: (@MainActor () -> Void)?

    #if canImport(UIKit)
    private let imageToCrop: UIImage
    private let onComplete: @MainActor (UIImage?) -> Void

    public init(
        imageToCrop: UIImage,
        maskShape: MaskShape,
        topAccessory: AnyView? = nil,
        configuration: SwiftyCropConfiguration = SwiftyCropConfiguration(),
        onCancel: (@MainActor () -> Void)? = nil,
        onComplete: @escaping @MainActor (UIImage?) -> Void
    ) {
        self.topAccessory = topAccessory
        self.imageToCrop = imageToCrop
        self.maskShape = maskShape
        self.configuration = configuration
        self.onCancel = onCancel
        self.onComplete = onComplete
    }
    #elseif canImport(AppKit)
    private let imageToCrop: NSImage
    private let onComplete: @MainActor (NSImage?) -> Void

    public init(
        imageToCrop: NSImage,
        maskShape: MaskShape,
        topAccessory: AnyView? = nil,
        configuration: SwiftyCropConfiguration = SwiftyCropConfiguration(),
        onCancel: (@MainActor () -> Void)? = nil,
        onComplete: @escaping @MainActor (NSImage?) -> Void
    ) {
        self.topAccessory = topAccessory
        self.imageToCrop = imageToCrop
        self.maskShape = maskShape
        self.configuration = configuration
        self.onCancel = onCancel
        self.onComplete = onComplete
    }
    #endif

    public var body: some View {
        #if canImport(UIKit)
        // On iOS/visionOS the view is typically presented in a sheet or fullScreenCover,
        // so it owns its navigation context.
        NavigationStack {
            CropView(
                image: imageToCrop,
                maskShape: maskShape,
                topAccessory: topAccessory,
                configuration: configuration,
                onCancel: onCancel,
                onComplete: onComplete
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        #else
        // On macOS the consumer provides a NavigationStack via navigationDestination;
        // CropView just renders its toolbar into the existing navigation bar.
        CropView(
            image: imageToCrop,
            maskShape: maskShape,
            topAccessory: topAccessory,
            configuration: configuration,
            onCancel: onCancel,
            onComplete: onComplete
        )
        #endif
    }
}

#Preview {
    #if canImport(UIKit)
    SwiftyCropView(imageToCrop: UIImage(systemName: "photo")!, maskShape: .circle) { _ in }
    #else
    NavigationStack {
        SwiftyCropView(imageToCrop: NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!, maskShape: .circle) { _ in }
    }
    #endif
}
