import SwiftUI

struct DelayedProgressLayer: View {
  let configuration: SwiftyCropConfiguration
  let localizableTableName: String
  let delay: Duration

  @State private var isVisible = false

  var body: some View {
    Group {
      if isVisible {
        ProgressLayer(configuration: configuration, localizableTableName: localizableTableName)
      }
    }
    .task {
      guard delay > .zero else {
        isVisible = true
        return
      }

      do {
        try await Task.sleep(for: delay)
        isVisible = true
      } catch {
        // Removing this view cancels the delay when cropping finishes quickly.
      }
    }
  }
}

struct ProgressLayer: View {
  let configuration: SwiftyCropConfiguration
  let localizableTableName: String
  
  var body: some View {
    ZStack {
      configuration.colors.background.opacity(0.4)
        .ignoresSafeArea()

      progressCard
        .padding(.vertical, 5)
        .padding(.horizontal, 20)
    }
    .transition(.opacity)
  }

  @ViewBuilder
  private var progressCard: some View {
    #if os(visionOS)
    fallbackCard
    #else
    if #available(iOS 26, macOS 26, *) {
      progressContent
        .glassEffect(
          .regular.tint(configuration.colors.background.opacity(0.8)),
          in: RoundedRectangle(cornerRadius: 12)
        )
    } else {
      fallbackCard
    }
    #endif
  }

  private var fallbackCard: some View {
    progressContent
      .frame(width: 120, height: 110)
      .background(configuration.colors.background.opacity(0.8))
      .cornerRadius(12)
  }

  private var progressContent: some View {
    VStack(alignment: .center, spacing: 20) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: configuration.colors.interactionInstructions))
        .scaleEffect(1.2)

      Text(
        configuration.texts.progressLayerText ??
        NSLocalizedString("processing_label", tableName: localizableTableName, bundle: .module, comment: "")
      )
      .font(.body)
      .foregroundColor(configuration.colors.interactionInstructions)
    }
    .padding(25)
  }
}

#Preview {
  ProgressLayer(configuration: .init(), localizableTableName: "Localizable")
}
