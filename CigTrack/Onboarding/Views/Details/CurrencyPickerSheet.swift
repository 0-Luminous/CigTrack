import SwiftUI

struct CurrencyPickerSheet: View {
    let supportedCurrencies: [Currency]
    @Binding var selection: Currency
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredCurrencies) { currency in
                        Button {
                            selection = currency
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(" \(currency.code)")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(currency.localizedName)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                if currency.code == selection.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(OnboardingTheme.accentStart)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 100)
                .padding(.bottom, 120)
            }
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .padding(.leading, 10)
                TextField(LocalizedStringKey("onboarding_currency_search_placeholder"), text: $searchText)
                    .padding(.vertical, 15)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
            }
            .glassEffect()
            .padding(16)
        }
    }

    private var filteredCurrencies: [Currency] {
        guard !searchText.isEmpty else { return supportedCurrencies }
        let term = searchText.lowercased()
        return supportedCurrencies.filter { currency in
            currency.code.lowercased().contains(term) ||
            currency.localizedName.lowercased().contains(term) ||
            currency.symbol.lowercased().contains(term)
        }
    }
}
