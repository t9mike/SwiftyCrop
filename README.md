# SwiftyCrop - SwiftUI
[![Build](https://github.com/benedom/SwiftyCrop/actions/workflows/build-swift.yml/badge.svg?branch=master)](https://github.com/benedom/SwiftyCrop/actions/workflows/build-swift.yml)
![Static Badge](https://img.shields.io/badge/Platform%20-%20iOS%20-%20light_green)
![Static Badge](https://img.shields.io/badge/iOS%20-%20%3E%2016.0%20-%20light_green)
![Static Badge](https://img.shields.io/badge/Platform%20-%20visionOS%20-%20light_green)
![Static Badge](https://img.shields.io/badge/visionOS%20-%20%3E%201.0%20-%20light_green)
![Static Badge](https://img.shields.io/badge/Platform%20-%20macOS%20-%20light_green)
![Static Badge](https://img.shields.io/badge/macOS%20-%20%3E%2013.0%20-%20light_green)
![Static Badge](https://img.shields.io/badge/Swift%20-%20%3E%205.9%20-%20orange)
<a href="LICENSE.md">
  <img src="https://img.shields.io/badge/License%20-%20MIT%20-%20blue" alt="License - MIT">
</a>

<p align="center">
  <img src="Assets/demo.gif" alt="SwiftyCrop example usage" width="250px"/>
</p>

<div align="center">

| Circle Mask Shape | Square Mask Shape |
|:-----------------:|:-----------------:|
| <img src="Assets/circle_crop.png" width="200px"/> | <img src="Assets/square_crop.png" width="200px"/> |

</div>

## 🔭 Overview
SwiftyCrop allows users to seamlessly crop images within their SwiftUI applications. It provides a user-friendly interface that makes cropping an image as simple as selecting the desired area.

With SwiftyCrop, you can easily adjust the cropping area, maintain aspect ratio, zoom in and out for precise cropping. You can also specify the cropping mask to be a square, circle or rectangle with custom aspect ratio. SwiftyCrop is highly customizable, you can adjust texts, fonts and colors that are used.

SwiftyCrop currently supports iOS, iPadOS, visionOS and macOS natively.

The following languages are supported & localized:
- 🇬🇧 English
- 🇩🇪 German
- 🇫🇷 French
- 🇮🇹 Italian
- 🇷🇺 Russian
- 🇪🇸 Spanish
- 🇹🇷 Turkish
- 🇺🇦 Ukrainian
- 🇭🇺 Hungarian
- 🇧🇷 Brazilian Portuguese
- 🇰🇷 Korean
- 🇯🇵 Japanese
- 🇨🇳 Chinese
- 🇫🇮 Finnish
- 🌐 Traditional Chinese

The localization file can be found in `Sources/SwiftyCrop/Resources`.

## 📕 Contents

- [Requirements](#-requirements)
- [Installation](#-installation)
- [Demo App](#-demo-app)
- [Usage](#-usage)
- [Aspect Ratio Resizing](#-aspect-ratio-resizing)
- [Zoom Slider](#-zoom-slider)
- [iOS 26 & Liquid Glass](#-ios-26--liquid-glass)
- [Contributors](#-contributors)
- [License](#-license)

## 🧳 Requirements

Deployment targets (where your app can run):

- iOS 16.0 or later
- visionOS 1.0 or later
- macOS 13.0 or later

Build requirements (the toolchain you compile with):

- Xcode 26.0 or later
- Swift 5.9 or later

> SwiftyCrop must be built with Xcode 26+ because it references iOS/macOS 26 SDK APIs (e.g. Liquid Glass effects). It still *deploys* to the OS versions listed above — older OS versions fall back to the non-glass UI at runtime.


## 💻 Installation
There are two ways to use SwiftyCrop in your project:
- using Swift Package Manager
- manual install (embed Xcode Project)

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

To integrate `SwiftyCrop` into your Xcode project using Xcode 26.0 or later, specify it in `File > Swift Packages > Add Package Dependency...`:

```ogdl
https://github.com/benedom/SwiftyCrop
```

### Manually

If you prefer not to use any of dependency managers, you can integrate `SwiftyCrop` into your project manually. Put `Sources/SwiftyCrop` folder in your Xcode project. Make sure to enable `Copy items if needed` and `Create groups`.

## 📱 Demo App

To get a feeling how `SwiftyCropView` works you can run the demo app (thanks to [@leoz](https://github.com/leoz)).

## 🛠️ Usage

### Quick Start
This example shows how to display `SwiftyCropView` in a full screen cover after an image has been set.
```swift
import SwiftUI
import SwiftyCrop

struct ExampleView: View {
    @State private var showImageCropper: Bool = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack {
            /*
            Update `selectedImage` with the image you want to crop,
            e.g. after picking it from the library or downloading it.

            As soon as you have done this, toggle `showImageCropper`.
            
            Below is a sample implementation:
             */

             Button("Crop downloaded image") {
                Task {
                    selectedImage = await downloadExampleImage()
                    showImageCropper.toggle()
                }
             }

        }
        .fullScreenCover(isPresented: $showImageCropper) {
            if let selectedImage = selectedImage {
                SwiftyCropView(
                    imageToCrop: selectedImage,
                    maskShape: .square
                ) { croppedImage in
                    // Do something with the returned, cropped image
                }
            }
        }
    }

    // Example function for downloading an image
    private func downloadExampleImage() async -> UIImage? {
        let urlString = "https://picsum.photos/1000/1200"
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data)
        else { return nil }

        return image
    }
}
```

:bangbang: NOTE :bangbang:
```
If you want to display `SwiftyCrop` inside a sheet, use `NavigationView` instead of `NavigationStack` in case you want to wrap it.
```

SwiftyCrop supports three different mask shapes for cropping:
- `circle`
- `square`
- `rectangle`

This is only the shape of the mask the user will see when cropping the image. The resulting, cropped image will always be a square by default when using `circle` or `square`. To get a circular cropped image, you can override this using a configuration.

You can also configure `SwiftyCropView` by passing a `SwiftyCropConfiguration`. A configuration has the following properties:

| Property      | Description |
| ----------- | ----------- |
| `maxMagnificationScale` | `CGFloat`: The maximum scale factor that the image can be magnified while cropping. Defaults to `4.0`. |
| `maskRadius` | `CGFloat`: The radius of the mask used for cropping. Defaults to `130`. A good way is to make it dependend on the screens size. |
| `cropImageCircular` | `Bool`: When using the cropping mask `circle`, whether the resulting image should also be masked as circle. Defaults to `false`. |
| `rotateImage` | `Bool`: Whether the image can be rotated when cropping using pinch gestures. Defaults to `false`. |
| `rotateImageWithButtons` | `Bool`: Option to show rotation buttons for rotating. Defaults to `false`. |
| `showsZoomSlider` | `Bool`: Whether a zoom slider is shown for input devices that cannot pinch-to-zoom. Replaces the interaction instructions text while shown. Defaults to `false`. |
| `zoomSensitivity` | `CGFloat`: Zoom sensitivity when cropping. Increase to make zoom faster / less sensitive. Defaults to `1.0`. |
| `rectAspectRatio` | `CGFloat`: The aspect ratio to use when a rectangular mask shape is used. Defaults to `4:3`. |
| `allowAspectRatioResizing` | `Bool`: When using the `rectangle` mask shape, whether the user can freely resize the aspect ratio by dragging the edge handles. Defaults to `false`. |
| `minAspectRatio` | `CGFloat`: The minimum allowed aspect ratio (width / height) when `allowAspectRatioResizing` is enabled. Defaults to `0.1`. |
| `maxAspectRatio` | `CGFloat`: The maximum allowed aspect ratio (width / height) when `allowAspectRatioResizing` is enabled. Defaults to `10.0`. |
| `dismissesOnCompletion` | `Bool`: Whether the cropping view dismisses itself after the save or cancel button was tapped. Set to `false` if the presenting view handles the dismissal itself. Defaults to `true`. |
| `texts` | `Texts`: Defines custom texts for the buttons and instructions. Defaults to using localized strings from resources. |
| `fonts` | `Fonts`: Defines custom fonts for the buttons and instructions. Defaults to using system font. |
| `colors` | `Colors`: Defines custom colors for the texts, buttons and background. Defaults to white text and black background. See [iOS 26 & Liquid Glass](#-ios-26--liquid-glass) for how the button colors behave with and without Liquid Glass. |

Create a configuration like this:
```swift
let configuration = SwiftyCropConfiguration(
    maxMagnificationScale: 4.0,
    maskRadius: 130,
    cropImageCircular: false,
    rotateImage: false,
    rotateImageWithButtons: false,
    showsZoomSlider: false,
    zoomSensitivity: 1.0,
    rectAspectRatio: 4/3,
    texts: SwiftyCropConfiguration.Texts(
        cancelButton: "Cancel",
        interactionInstructions: "Custom instruction text",
        saveButton: "Save",
        zoomSliderLabel: "Zoom"
    ),
    fonts: SwiftyCropConfiguration.Fonts(
        cancelButton: Font.system(size: 12),
        interactionInstructions: Font.system(size: 14),
        saveButton: Font.system(size: 12)
    ),
    colors: SwiftyCropConfiguration.Colors(
        cancelButton: Color.red,
        interactionInstructions: Color.white,
        saveButton: Color.blue,
        // Only has an effect with Liquid Glass, where it tints the save button's glass background
        saveButtonBackground: Color.yellow,
        background: Color.gray,
        zoomSlider: Color.white
    )
)
```
and use it like this:
```swift
.fullScreenCover(isPresented: $showImageCropper) {
            if let selectedImage = selectedImage {
                SwiftyCropView(
                    imageToCrop: selectedImage,
                    maskShape: .square,
                    // Use the configuration
                    configuration: configuration
                ) { croppedImage in
                    // Do something with the returned, cropped image
                }
            }
        }
```

## ↔️ Aspect Ratio Resizing

When using the `rectangle` mask shape, you can allow users to freely adjust the crop area's aspect ratio at runtime by dragging handles on the edges of the mask. Enable this via `allowAspectRatioResizing` in the configuration and optionally constrain the range with `minAspectRatio` and `maxAspectRatio`.

```swift
let configuration = SwiftyCropConfiguration(
    rectAspectRatio: 4/3,
    allowAspectRatioResizing: true,
    minAspectRatio: 0.5,  // narrowest: 1:2
    maxAspectRatio: 3.0   // widest: 3:1
)
```

<p align="center">
    <img src="Assets/aspect_crop.png" style="margin: auto; width: 250px"/>
</p>

## 🔍 Zoom Slider

Zooming is normally done with a pinch gesture. That gesture is not available on every input device — a mouse on macOS or Catalyst cannot perform it, and neither can VoiceOver, Switch Control or Full Keyboard Access. Enable `showsZoomSlider` to additionally offer a slider, which drives the exact same scale as the pinch gesture.

```swift
let configuration = SwiftyCropConfiguration(
    showsZoomSlider: true,
    texts: SwiftyCropConfiguration.Texts(
        zoomSliderLabel: "Zoom" // Accessibility label, defaults to the localized value
    ),
    colors: SwiftyCropConfiguration.Colors(
        zoomSlider: Color.white
    )
)
```

Because the host app knows its own input devices best, this is a plain toggle rather than an automatic platform check — there is no reliable API to detect whether a trackpad is present.

> :bangbang: The slider occupies the same toolbar slot as the interaction instructions. While `showsZoomSlider` is enabled, the instructions text is not shown and `texts.interactionInstructions` has no effect.

## 🚪 Dismissal

By default the cropping view dismisses itself once the save or cancel button was tapped, right after `onComplete` / `onCancel` were called. If the presenting view needs to control the dismissal, set `dismissesOnCompletion` to `false` and perform the dismissal yourself.

```swift
let configuration = SwiftyCropConfiguration(
    dismissesOnCompletion: false
)
```

This is useful when the cropped image is processed before the UI moves on, for example when uploading it: the cropping view stays on screen until the upload succeeded, so a failed upload can show an error instead of losing the crop.

> :bangbang: With `dismissesOnCompletion` set to `false`, SwiftyCrop never dismisses itself. The presenting view is responsible for dismissing it in `onComplete` and `onCancel`, otherwise the cropping view stays on screen.

## 🪟 iOS 26 & Liquid Glass

To adopt the new Liquid Glass design Apple introduced with iOS 26, SwiftyCrop renders a UI that reflects this design (the screenshots above). This replaces text buttons with icon buttons and much more. It is applied automatically whenever iOS 26, visionOS 26 or macOS 26 is available; older OS versions fall back to the classic UI shown below. There is no toggle for it.

<p align="center">
    <img src="Assets/legacy_square.png" style="margin: auto; width: 250px"/>
</p>

### Colors

The foreground colors of `SwiftyCropConfiguration.Colors` (`cancelButton`, `rotateButton`, `resetRotationButton`, `saveButton`) apply on every OS version. They color the button texts on older versions and the button icons with Liquid Glass.

The matching `…Background` colors (`cancelButtonBackground`, `rotateButtonBackground`, `resetRotationButtonBackground`, `saveButtonBackground`) only have an effect with Liquid Glass, where they tint the glass background of a button. A `.clear` background, which is the default for every button except the save button, keeps the plain, untinted glass look.

On iOS, a button with a background other than `.clear` is rendered with a prominent glass style, which picks the icon color itself so it contrasts with the tint. The foreground color of such a button therefore has no effect. With the default yellow save button background this results in a dark checkmark, for example.

Since `texts` and `fonts` only apply to button texts, they have no effect with Liquid Glass either, as the buttons show icons there.

> The toolbar itself is transparent, so button texts and icons are drawn on top of `background` rather than on a system bar. Pick colors that contrast with `background` and avoid color scheme dependent ones such as `.primary`, as those flip with the users appearance setting while `background` does not.

## 👨‍💻 Contributors

All issue reports, feature requests, pull requests and GitHub stars are welcomed and much appreciated.

Thanks to [@leoz](https://github.com/leoz) for adding the circular crop mode, the demo app and the rotation functionality 🎉

Thanks to [@kevin-hv](https://github.com/kevin-hv) for adding the hungarian localization 🇭🇺

Thanks to [@Festanny](https://github.com/Festanny) for helping with the recangular cropping functionality 🎉

Thanks to [@lipej](https://github.com/lipej) for adding the brazilian portugese localization 🇧🇷🇵🇹

Thanks to [@insub](https://github.com/insub4067) for adding the korean localization 🇰🇷

Thanks to [@yhirano](https://github.com/yhirano) for adding the japanese localization 🇯🇵

Thanks to [@yefimtsev](https://github.com/yefimtsev) for adding the ability to customize fonts and colors 🖼️

Thanks to [@SuperY](https://github.com/SuperY) for adding the chinese localization 🇨🇳

Thanks to [@mosliem](https://github.com/mosliem) for adding the cropping in background thread 🧵

Thanks to [@krayc425](https://github.com/krayc425) for adding visionOS support 🕶️

Thanks to [@KuuttiProductions](https://github.com/KuuttiProductions) for adding the finnish localization 🇫🇮

Thanks to [@puyanlin](https://github.com/puyanlin) for adding the traditional chinese localization 🌐

Thanks to [@navanchauhan](https://github.com/navanchauhan) for adding native macOS support 🖥️

Thanks to [@andrewhanshaw](https://github.com/andrewhanshaw) for adding the aspect ratio resizing functionality 🎉

Another thanks to [@andrewhanshaw](https://github.com/andrewhanshaw) for overhauling the cropping UI with a native SwiftUI toolbar, native macOS window support and a unified Liquid Glass design 🛠️

Thanks to [@ezathashim](https://github.com/ezathashim) for adding the zoom slider for input devices without pinch-to-zoom and for making the dismissal optional 🔍

## 📃 License

`SwiftyCrop` is available under the MIT license. See the [LICENSE](https://github.com/benedom/SwiftyCrop/blob/master/LICENSE.md) file for more info.
