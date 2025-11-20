import SwiftUI

struct OnboardingMethodPickerView: View {
    let selectedMethod: NicotineMethod?
    let onMethodSelected: (NicotineMethod) -> Void
    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 20)]

    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("onboarding_step_one")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("onboarding_method_card_hint_copy")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 130)

                    LazyVGrid(columns: columns, spacing: 20) {
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
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 36)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Methods - RU") {
    OnboardingMethodPickerView(selectedMethod: .cigarettes, onMethodSelected: { _ in })
        .environment(\.locale, .init(identifier: "ru"))
}
