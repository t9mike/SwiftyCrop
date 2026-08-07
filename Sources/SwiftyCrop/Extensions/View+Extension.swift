import SwiftUI

struct SizePreferenceKey: PreferenceKey {
  static let defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

#if os(iOS)
@available(iOS 26, *)
struct ScrollOffsetToolbarTriggerModifier: ViewModifier {
  @State private var scrollPosition = ScrollPosition(y: 20)
  func body(content: Content) -> some View {
    GeometryReader { geo in
      ScrollView {
        VStack(spacing: 0) {
          Color.clear.frame(width: geo.size.width, height: 20)
          content
            .frame(width: geo.size.width, height: geo.size.height)
        }
      }
      .scrollPosition($scrollPosition)
      .scrollDisabled(true)
      .scrollEdgeEffectStyle(.soft, for: .top)
    }
  }
}
#endif

extension View {
  @ViewBuilder
  func toolbarButtonLabelStyle() -> some View {
    if #available(iOS 26, visionOS 26.0, macOS 26.0, *) {
      self.labelStyle(.iconOnly)
    } else {
      self.labelStyle(.titleOnly)
    }
  }

  /// Tints the Liquid Glass background of a toolbar button.
  /// A `.clear` tint keeps the plain glass look, so the system styling is left untouched.
  /// Has no effect below iOS/visionOS/macOS 26, where there is no glass to tint.
  @ViewBuilder
  func tintedGlassEffect(_ tint: Color) -> some View {
    if tint == .clear {
      self
    } else if #available(iOS 26, visionOS 26.0, macOS 26.0, *) {
      #if os(iOS)
        // A manually applied `glassEffect` is ignored for buttons inside a real toolbar, so the
        // prominent button style is the only way to tint them. It picks the icon color itself for
        // contrast against the tint, so the configured foreground color has no effect on such a button.
        self.buttonStyle(GlassProminentButtonStyle()).tint(tint)
      #elseif os(macOS)
        self.glassEffect(.regular.tint(tint).interactive())
      #else
        self
      #endif
    } else {
      self
    }
  }

  // Scroll offset toolbar trigger extension. Only applies to iOS 26+
  @ViewBuilder
  func scrollOffsetToolbarTrigger() -> some View {
    if #available(iOS 26, visionOS 26.0, macOS 26.0, *) {
      #if os(iOS)
        self.modifier(ScrollOffsetToolbarTriggerModifier())
      #else
        self
      #endif
    } else {
      self
    }
  }

  /// Calls `perform` whenever this view's size changes (including after first layout).
  /// Uses `PreferenceKey` so it's compatible with all supported OS versions.
  @ViewBuilder
  func onSizeChange(_ perform: @escaping (CGSize) -> Void) -> some View {
    if #available(iOS 26, visionOS 26.0, macOS 26.0, *) {
      self
    } else {
      background(
        GeometryReader { geo in
          Color.clear.preference(key: SizePreferenceKey.self, value: geo.size)
        }
      )
      .onPreferenceChange(SizePreferenceKey.self, perform: perform)
    }
  }
}
