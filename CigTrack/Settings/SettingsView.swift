import CoreData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appViewModel: AppViewModel
    @ObservedObject var user: User

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false
    @State private var selectedMethod: NicotineMethod = .cigarettes
    @State private var dailyLimit: Double = 10
    @State private var showMethodPicker = false
    @State private var showModePicker = false
    @State private var showAppearancePicker = false
    @State private var selectedMode: OnboardingMode = .tracking
    @State private var appearancePickerMode: ColorScheme = .light

    private var backgroundStyle: DashboardBackgroundStyle {
        style(for: colorScheme)
    }

    private var cardStrokeColor: Color {
        switch backgroundStyle {
        case .sunrise, .amber, .sunsetAura, .mintBreeze, .iceCrystal, .coralSunset, .auroraGlow, .skyMorning:
            return Color.black.opacity(0.12)
        default:
            return Color.white.opacity(0.15)
        }
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
            SettingsMethodPickerView(selectedMethod: selectedMethod) { method in
                selectedMethod = method
            }
        }
        .fullScreenCover(isPresented: $showModePicker) {
            modePickerScreen
        }
            .sheet(isPresented: $showAppearancePicker) {
                appearancePickerSheet
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
    private var primaryTextColor: Color { backgroundStyle.primaryTextColor }
    private var appearancePickerDescription: String {
        appearancePickerMode == .dark
            ? NSLocalizedString("Shown when the app is in Dark Mode.", comment: "Dark appearance description")
            : NSLocalizedString("Shown when the app is in Light Mode.", comment: "Light appearance description")
    }

    private func style(for scheme: ColorScheme) -> DashboardBackgroundStyle {
        ensureAppearanceMigration()
        let index = backgroundIndex(for: scheme)
        return DashboardBackgroundStyle(rawValue: index) ?? DashboardBackgroundStyle.default(for: scheme)
    }

    private func backgroundIndex(for scheme: ColorScheme) -> Int {
        scheme == .dark ? backgroundIndexDark : backgroundIndexLight
    }

    private func updateBackgroundIndex(_ newValue: Int, for scheme: ColorScheme) {
        if scheme == .dark {
            backgroundIndexDark = newValue
        } else {
            backgroundIndexLight = newValue
        }
    }

    private func ensureAppearanceMigration() {
        guard !appearanceStylesMigrated else { return }
        backgroundIndexLight = legacyBackgroundIndex
        backgroundIndexDark = legacyBackgroundIndex
        appearanceStylesMigrated = true
    }

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
            Button {
                showAppearancePicker = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(backgroundStyle.previewGradient)
                            .frame(width: 56, height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)

                        Image(systemName: "paintpalette.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard style")
                            .font(.body.weight(.semibold))
                        Text(backgroundStyle.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    var guidanceSection: some View {
        settingsCard(title: "Guidance") {
            VStack(alignment: .leading, spacing: 16) {
                ModeSpotlightCardView(mode: selectedMode,
                                      arrowColor: primaryTextColor) {
                    showModePicker = true
                }
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

    var appearancePickerSheet: some View {
        ensureAppearanceMigration()
        return NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Theme", selection: $appearancePickerMode) {
                            Text("Light").tag(ColorScheme.light)
                            Text("Dark").tag(ColorScheme.dark)
                        }
                        .pickerStyle(.segmented)

                        Text(appearancePickerDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                              spacing: 16) {
                        ForEach(DashboardBackgroundStyle.appearanceOptions) { style in
                            let isSelected = backgroundIndex(for: appearancePickerMode) == style.rawValue
                            Button {
                                updateBackgroundIndex(style.rawValue, for: appearancePickerMode)
                            } label: {
                                VStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(style.previewGradient)
                                        .frame(height: 80)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(isSelected ? Color.white : Color.white.opacity(0.4),
                                                        lineWidth: isSelected ? 3 : 1)
                                        )
                                        .overlay(alignment: .topTrailing) {
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .shadow(radius: 6)
                                                    .offset(x: -8, y: 8)
                                            }
                                        }

                                    Text(style.name)
                                        .font(.footnote.weight(isSelected ? .semibold : .regular))
                                        .foregroundStyle(isSelected ? .primary : .secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(.thinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(isSelected ? 0.7 : 0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Appearance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showAppearancePicker = false }
                }
                ToolbarItem(placement: .principal) {
                    Text("Choose Appearance")
                        .font(.headline)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            appearancePickerMode = colorScheme
        }
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
