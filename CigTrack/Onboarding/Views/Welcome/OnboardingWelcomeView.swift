import SwiftUI
#if os(iOS)
import UIKit
#endif

struct OnboardingWelcomeView: View {
    let appName: String
    @Binding var selectedMode: OnboardingMode
    let onStart: () -> Void

    private let modes = OnboardingMode.allCases
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            pager(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .ignoresSafeArea()
        }
    }

    private func pager(size: CGSize, safeAreaInsets: EdgeInsets) -> some View {
        let width = size.width
        let currentIndex = index(for: selectedMode)
        let dragProgress = width == 0 ? 0 : dragOffset / width

        return ZStack {
            backgroundLayer(size: size,
                            currentIndex: currentIndex,
                            dragProgress: dragProgress)

            HStack(spacing: 0) {
                ForEach(modes) { mode in
                    ModeSlide(appName: appName,
                              mode: mode,
                              selectedMode: selectedMode,
                              onStart: onStart,
                              safeAreaInsets: safeAreaInsets)
                        .frame(width: width, height: size.height)
                        .scaleEffect(mode == selectedMode ? 1 : 0.96)
                        .opacity(mode == selectedMode ? 1 : 0.72)
                        .animation(.easeInOut(duration: 0.25), value: selectedMode)
                }
            }
            .frame(width: size.width, alignment: .leading)
            .offset(x: -CGFloat(currentIndex) * width + dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = width * 0.25
                        var newIndex = currentIndex
                        if value.translation.width < -threshold {
                            newIndex = min(currentIndex + 1, modes.count - 1)
                        } else if value.translation.width > threshold {
                            newIndex = max(currentIndex - 1, 0)
                        }
                        guard newIndex != currentIndex else { return }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selectedMode = modes[newIndex]
                        }
                        provideHapticFeedback()
                    }
            )
        }
    }

    private func index(for mode: OnboardingMode) -> Int {
        modes.firstIndex(of: mode) ?? 0
    }

    private func provideHapticFeedback() {
#if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize,
                                 currentIndex: Int,
                                 dragProgress: CGFloat) -> some View {
        let clamped = max(-1, min(1, dragProgress))
        let baseOpacity = 1 - min(1, abs(clamped))

        backgroundImage(for: selectedMode, size: size)
            .opacity(baseOpacity)

        if clamped != 0 {
            let direction = clamped < 0 ? 1 : -1
            let targetIndex = currentIndex + direction
            if modes.indices.contains(targetIndex) {
                backgroundImage(for: modes[targetIndex], size: size)
                    .opacity(min(1, abs(clamped)))
            }
        }
    }

    private func backgroundImage(for mode: OnboardingMode, size: CGSize) -> some View {
        Image(mode.backgroundImageName)
            .resizable()
            .scaledToFill()
            .frame(width: size.width,
                   height: size.height,
                   alignment: .bottom) // keep bottom content visible
            .clipped()
            .ignoresSafeArea()
    }
}

private struct ModeSlide: View {
    let appName: String
    let mode: OnboardingMode
    let selectedMode: OnboardingMode
    let onStart: () -> Void
    let safeAreaInsets: EdgeInsets

    var body: some View {
        ZStack {
            headerLayer
            detailsLayer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private var headerLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(appName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("onboarding_mode_picker_title")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("onboarding_mode_picker_subtitle")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, safeAreaInsets.top + 28)

            Spacer()
        }
    }

    private var detailsLayer: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .center, spacing: 18) {
                VStack(alignment: .center, spacing: 12) {
                    Text(mode.titleKey)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 25)
                        .padding(.top, 12)
                    Text(mode.subtitleKey)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 25)
                        .padding(.bottom, 14)
                }
                .glassEffect(
                    .clear,
                    in: .rect(cornerRadius: 24)
                    )

                VStack(alignment: .leading, spacing: 10) {
                    ModeIndicator(selectedMode: selectedMode)
                    HStack {
                        Spacer()
                        Text("onboarding_mode_swipe_hint")
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                }
                Button(action: onStart) {
                    Text("onboarding_primary_cta")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                }
                .contentShape(Capsule())
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
                .shadow(color: Color.blue.opacity(0.3), radius: 18, x: 0, y: 10)
                .accessibilityHint(Text("onboarding_primary_cta_hint"))
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [
                    Color.black.opacity(0.98),
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.65),
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.05)
                ], startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}

private struct ModeIndicator: View {
    let selectedMode: OnboardingMode

    var body: some View {
        HStack(spacing: 10) {
            Spacer()
            ForEach(OnboardingMode.allCases) { mode in
                Capsule()
                    .fill(Color.white.opacity(mode == selectedMode ? 0.95 : 0.3))
                    .frame(width: mode == selectedMode ? 32 : 10, height: 4)
                    .animation(.easeInOut(duration: 0.25), value: selectedMode)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
    }
}

#Preview("Welcome - EN") {
    OnboardingWelcomeView(appName: "SmokeTracker",
                          selectedMode: .constant(.tracking),
                          onStart: {})
        .environment(\.locale, .init(identifier: "en"))
}
