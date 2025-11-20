import SwiftUI

struct MethodCardView: View {
    let method: NicotineMethod
    let isSelected: Bool

    var body: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 20) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(OnboardingTheme.primaryGradient)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(method.iconAssetName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    )
                    .shadow(color: OnboardingTheme.accentEnd.opacity(0.5), radius: 20, x: 0, y: 10)

                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey(method.localizationKey))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(method.descriptionKey))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(OnboardingTheme.accentStart)
                        .font(.title2)
                        .accessibilityHidden(true)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(isSelected ? OnboardingTheme.accentStart : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
