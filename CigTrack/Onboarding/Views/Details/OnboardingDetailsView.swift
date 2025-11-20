import SwiftUI

struct OnboardingDetailsView: View {
    let method: NicotineMethod
    @ObservedObject var viewModel: OnboardingViewModel
    let supportedCurrencies: [Currency]
    let onboardingCompleted: (NicotineProfile) -> Void
    let onBack: () -> Void

    @State private var errorMessage: String?
    @State private var isCurrencySheetPresented = false
    @State private var currencySearchText = ""

    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    GlassSection("onboarding_section_currency") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("onboarding_currency_picker_title")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                            currencyButton
                        }
                    }

                    formContent

                    if !viewModel.validationMessages.isEmpty {
                        ValidationCard(titleKey: "onboarding_validation_section",
                                       messages: viewModel.validationMessages,
                                       systemImage: "exclamationmark.triangle.fill",
                                       tint: .orange)
                    }

                    if !viewModel.warningMessages.isEmpty {
                        ValidationCard(titleKey: "onboarding_warning_section",
                                       messages: viewModel.warningMessages,
                                       systemImage: "info.circle.fill",
                                       tint: .yellow)
                    }

                    let helperTexts = viewModel.helperTextForCurrentMethod()
                    if !helperTexts.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("onboarding_helper_section")
                                    .font(.headline)
                                ForEach(helperTexts, id: \.self) { message in
                                    Text(message)
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationTitle(Text(LocalizedStringKey(method.localizationKey)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Label("back_button", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.white)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                Button(action: submit) {
                    Text("onboarding_continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                .disabled(!viewModel.isCurrentFormValid)
                .opacity(viewModel.isCurrentFormValid ? 1 : 0.5)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $isCurrencySheetPresented) {
            NavigationStack {
                CurrencyPickerSheet(supportedCurrencies: supportedCurrencies,
                                    selection: currencyBinding,
                                    searchText: $currencySearchText)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("back_button") {
                                isCurrencySheetPresented = false
                            }
                        }
                    }
                    .navigationTitle(Text("onboarding_currency_picker_title"))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
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

    private var currencyButton: some View {
        Button {
            isCurrencySheetPresented = true
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedCurrencyDescription)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(viewModel.currency(for: method).localizedName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .glassInputStyle()
        }
        .buttonStyle(.plain)
    }

    private var selectedCurrencyDescription: String {
        let currency = viewModel.currency(for: method)
        return "\(currency.code)"
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
