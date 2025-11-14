import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appViewModel: AppViewModel
    @ObservedObject var user: User

    @AppStorage("dashboardBackgroundIndex") private var backgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @State private var selectedMethod: NicotineMethod = .cigarettes
    @State private var dailyLimit: Double = 10
    @State private var showMethodPicker = false
    @State private var showModePicker = false
    @State private var selectedMode: OnboardingMode = .tracking

    private var backgroundStyle: DashboardBackgroundStyle {
        DashboardBackgroundStyle(rawValue: backgroundIndex) ?? .default
    }

    private var cardStrokeColor: Color {
        switch backgroundStyle {
        case .sunrise, .amber:
            return Color.black.opacity(0.12)
        default:
            return Color.white.opacity(0.15)
        }
    }

    private var modeSpotlightStrokeColor: Color {
        backgroundStyle.primaryTextColor.opacity(0.8)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundStyle.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        trackingSection
                        guidanceSection
                        appearanceSection
                        resetSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear(perform: synchronizeForm)
            .fullScreenCover(isPresented: $showMethodPicker) {
                OnboardingMethodPickerView(selectedMethod: selectedMethod) { method in
                    selectedMethod = method
                    showMethodPicker = false
                }
            }
            .fullScreenCover(isPresented: $showModePicker) {
                modePickerScreen
            }
        }
    }

    private func synchronizeForm() {
        selectedMethod = nicotineMethod(for: ProductType(rawValue: user.productType) ?? .cigarette)
        dailyLimit = Double(user.dailyLimit)
        selectedMode = .tracking
    }

    private func save() {
        user.productType = productType(for: selectedMethod).rawValue
        user.dailyLimit = Int32(dailyLimit)
        context.saveIfNeeded()
        dismiss()
    }
}

private extension SettingsView {
    var trackingSection: some View {
        settingsCard(title: "Tracking") {
            VStack(alignment: .leading, spacing: 16) {
                methodSelectionCard

                Stepper(value: $dailyLimit, in: 1...60, step: 1) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily limit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(dailyLimit)) per day")
                            .font(.body.weight(.semibold))
                    }
                }
            }
        }
    }

    var appearanceSection: some View {
        settingsCard(title: "Appearance") {
            backgroundSelectionRow
        }
    }

    var guidanceSection: some View {
        settingsCard(title: "Guidance") {
            VStack(alignment: .leading, spacing: 16) {
                modeSpotlight
                Text("Switch between focus modes to adjust the motivation and guidance you see across the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var resetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(role: .destructive) {
                appViewModel.resetOnboarding()
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Text("Reset onboarding")
                        .font(.body.weight(.semibold))
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.red.opacity(0.3))
            )

            Text("You can re-run the onboarding to change more details or start a new journey.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var modeSpotlight: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return Button {
            showModePicker = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                modeArtwork(for: selectedMode)
                    .frame(height: 180)
                    .clipShape(shape)
                    .overlay(
                        LinearGradient(colors: [
                            Color.black.opacity(0.85),
                            Color.black.opacity(0.45),
                            Color.black.opacity(0.05)
                        ], startPoint: .bottom, endPoint: .top)
                            .clipShape(shape)
                    )

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: modeSymbol(for: selectedMode))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Text("Active focus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .textCase(.uppercase)
                            .tracking(1)
                    }

                    Text(selectedMode.titleKey)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text(selectedMode.subtitleKey)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        ForEach(modeHighlights(for: selectedMode), id: \.self) { highlight in
                            Text(highlight)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }
            .padding(18)
            .frame(height: 180)
            .clipShape(shape)
            .overlay(
                shape
                    .strokeBorder(modeSpotlightStrokeColor, lineWidth: 1.8)
            )
        }
        .buttonStyle(.plain)
    }

    var modePickerScreen: some View {
        ZStack(alignment: .topTrailing) {
            OnboardingWelcomeView(appName: "SmokeTracker",
                                  selectedMode: $selectedMode) {
                showModePicker = false
            }
            .preferredColorScheme(.dark)

            Button {
                showModePicker = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                    .padding()
            }
        }
    }

    var methodSelectionCard: some View {
        Button {
            showMethodPicker = true
        } label: {
            SettingsMethodCardView(method: selectedMethod,
                                   backgroundStyle: backgroundStyle)
        }
        .buttonStyle(.plain)
    }

    var backgroundSelectionRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dashboard Background")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(DashboardBackgroundStyle.allCases) { style in
                        let isSelected = backgroundIndex == style.rawValue
                        Button {
                            backgroundIndex = style.rawValue
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(style.previewGradient)
                                    .frame(width: 140, height: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(isSelected ? Color.white : Color.white.opacity(0.4),
                                                    lineWidth: isSelected ? 3 : 1)
                                    )
                                    .overlay(alignment: .topTrailing) {
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .shadow(radius: 4)
                                                .offset(x: -8, y: 8)
                                        }
                                    }

                                Text(style.name)
                                    .font(.footnote.weight(isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? .primary : .secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 140)
                            .shadow(color: isSelected ? Color.black.opacity(0.25) : .clear,
                                    radius: isSelected ? 12 : 0,
                                    y: isSelected ? 8 : 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    func settingsCard<Content: View>(title: LocalizedStringKey,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cardStrokeColor, lineWidth: 1)
        )
    }

    func modeArtwork(for mode: OnboardingMode) -> some View {
        Image(mode.backgroundImageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    func modeSymbol(for mode: OnboardingMode) -> String {
        switch mode {
        case .tracking:
            return "target"
        case .gradualReduction:
            return "speedometer"
        case .quitNow:
            return "flame.fill"
        }
    }

    func modeHighlights(for mode: OnboardingMode) -> [String] {
        switch mode {
        case .tracking:
            return ["Awareness", "Flexible pacing"]
        case .gradualReduction:
            return ["Weekly goals", "Gentle cutbacks"]
        case .quitNow:
            return ["High accountability", "Crisis tools"]
        }
    }

    func nicotineMethod(for product: ProductType) -> NicotineMethod {
        switch product {
        case .cigarette:
            return .cigarettes
        case .vape:
            return .refillableVape
        }
    }

    func productType(for method: NicotineMethod) -> ProductType {
        switch method {
        case .cigarettes, .heatedTobacco, .snusOrPouches:
            return .cigarette
        case .disposableVape, .refillableVape:
            return .vape
        }
    }
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        SettingsView(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
