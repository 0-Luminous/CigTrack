import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var path: [OnboardingRoute] = []

    private let appName = "SmokeTracker"

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingWelcomeView(appName: appName) {
                path.append(.methodPicker)
            }
            .navigationDestination(for: OnboardingRoute.self) { route in
                switch route {
                case .methodPicker:
                    OnboardingMethodPickerView(selectedMethod: viewModel.selectedMethod) { method in
                        viewModel.select(method: method)
                        path = [.methodPicker, .methodDetails(method)]
                    }
                    .navigationTitle(Text("onboarding_method_title"))
                    .navigationBarTitleDisplayMode(.large)
                case .methodDetails(let method):
                    OnboardingDetailsView(method: method,
                                          viewModel: viewModel,
                                          supportedCurrencies: viewModel.currencyOptions) { profile in
                        appViewModel.completeOnboarding(with: profile)
                    } onBack: {
                        path = [.methodPicker]
                    }
                    .navigationBarBackButtonHidden()
                }
            }
        }
    }
}

private enum OnboardingRoute: Hashable {
    case methodPicker
    case methodDetails(NicotineMethod)
}

struct OnboardingWelcomeView: View {
    let appName: String
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(String(format: NSLocalizedString("onboarding_welcome_title", comment: ""), appName))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("onboarding_welcome_subtitle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button(action: onStart) {
                Text("onboarding_primary_cta")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.accentColor))
                    .foregroundStyle(Color(.systemBackground))
            }
            .accessibilityHint(Text("onboarding_primary_cta_hint"))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
    }
}

struct OnboardingMethodPickerView: View {
    let selectedMethod: NicotineMethod?
    let onMethodSelected: (NicotineMethod) -> Void
    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(NicotineMethod.allCases) { method in
                    Button {
                        onMethodSelected(method)
                    } label: {
                        MethodCardView(method: method, isSelected: method == selectedMethod)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("onboarding_method_card_hint"))
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

private struct MethodCardView: View {
    let method: NicotineMethod
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: method.iconSystemName)
                .font(.largeTitle)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor.opacity(0.1)))
                .foregroundStyle(.primary)
            Text(LocalizedStringKey(method.localizationKey))
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct OnboardingDetailsView: View {
    let method: NicotineMethod
    @ObservedObject var viewModel: OnboardingViewModel
    let supportedCurrencies: [Currency]
    let onboardingCompleted: (NicotineProfile) -> Void
    let onBack: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Form {
                Section(header: Text("onboarding_section_currency")) {
                    currencyPicker
                }

                formContent

                if !viewModel.validationMessages.isEmpty {
                    Section {
                        ValidationListView(messages: viewModel.validationMessages,
                                           systemImage: "exclamationmark.triangle.fill",
                                           tint: .orange)
                    } header: {
                        Text("onboarding_validation_section")
                    }
                }

                if !viewModel.warningMessages.isEmpty {
                    Section {
                        ValidationListView(messages: viewModel.warningMessages,
                                           systemImage: "info.circle.fill",
                                           tint: .yellow)
                    } header: {
                        Text("onboarding_warning_section")
                    }
                }

                let helperTexts = viewModel.helperTextForCurrentMethod()
                if !helperTexts.isEmpty {
                    Section {
                        ForEach(helperTexts, id: \.self) { message in
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel(message)
                        }
                    } header: {
                        Text("onboarding_helper_section")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text(LocalizedStringKey(method.localizationKey)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onBack) {
                        Label("back_button", systemImage: "chevron.left")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                Button {
                    submit()
                } label: {
                    Text("onboarding_continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.accentColor))
                        .foregroundStyle(Color(.systemBackground))
                }
                .disabled(!viewModel.isCurrentFormValid)
                .opacity(viewModel.isCurrentFormValid ? 1 : 0.5)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var formContent: some View {
        switch method {
        case .cigarettes:
            CigarettesFormView(config: $viewModel.cigarettesConfig)
        case .disposableVape:
            DisposableVapeFormView(config: $viewModel.disposableVapeConfig)
        case .refillableVape:
            RefillableVapeFormView(config: $viewModel.refillableVapeConfig)
        case .heatedTobacco:
            HeatedTobaccoFormView(config: $viewModel.heatedTobaccoConfig)
        case .snusOrPouches:
            SnusFormView(config: $viewModel.snusConfig)
        }
    }

    private var currencyBinding: Binding<Currency> {
        Binding(
            get: { viewModel.currency(for: method) },
            set: { viewModel.updateCurrency($0) }
        )
    }

    private func submit() {
        do {
            viewModel.select(method: method)
            let profile = try viewModel.persistProfile()
            onboardingCompleted(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private var currencyPicker: some View {
        let picker = Picker("onboarding_currency_picker_title", selection: currencyBinding) {
            ForEach(supportedCurrencies) { currency in
                Text("\(currency.symbol) \(currency.code) - \(currency.localizedName)")
                    .tag(currency)
            }
        }
        if #available(iOS 17, *) {
            picker.pickerStyle(.navigationLink)
        } else {
            picker.pickerStyle(.menu)
        }
    }
}

private struct ValidationListView: View {
    let messages: [String]
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(messages, id: \.self) { message in
                Label {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Welcome - EN") {
    OnboardingWelcomeView(appName: "SmokeTracker", onStart: {})
        .environment(\.locale, .init(identifier: "en"))
}

#Preview("Methods - RU") {
    OnboardingMethodPickerView(selectedMethod: .cigarettes, onMethodSelected: { _ in })
        .environment(\.locale, .init(identifier: "ru"))
}

#Preview("Cigarette Form") {
    let viewModel = OnboardingViewModel()
    viewModel.select(method: .cigarettes)
    return NavigationStack {
        OnboardingDetailsView(method: .cigarettes,
                              viewModel: viewModel,
                              supportedCurrencies: viewModel.currencyOptions,
                              onboardingCompleted: { _ in }, onBack: {})
    }
    .environment(\.locale, .init(identifier: "en"))
}
