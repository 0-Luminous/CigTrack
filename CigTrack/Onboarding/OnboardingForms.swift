import SwiftUI

struct CigarettesFormView: View {
    @Binding var config: CigarettesConfig

    var body: some View {
        VStack(spacing: 24) {
            GlassSection("onboarding_section_consumption") {
                IntegerSliderField(titleKey: "cigarettes_per_day_title",
                                   subtitleKey: "cigarettes_per_day_subtitle",
                                   value: $config.cigarettesPerDay,
                                   range: 1...99,
                                   rangeDescriptionKey: "cigarettes_per_day_range")
                IntegerSliderField(titleKey: "cigarettes_per_pack_title",
                                   subtitleKey: "cigarettes_per_pack_subtitle",
                                   value: $config.cigarettesPerPack,
                                   range: 10...40,
                                   rangeDescriptionKey: "cigarettes_per_pack_range")
            }

            GlassSection("onboarding_section_cost") {
                DecimalField(titleKey: "pack_price_title",
                             placeholderKey: "pack_price_placeholder",
                             value: $config.packPrice)
                InfoTipView(textKey: "pack_price_tip")
            }
        }
    }
}

struct DisposableVapeFormView: View {
    @Binding var config: DisposableVapeConfig

    var body: some View {
        VStack(spacing: 24) {
            GlassSection("onboarding_section_consumption") {
                IntegerSliderField(titleKey: "puffs_per_device_title",
                                   subtitleKey: "puffs_per_device_subtitle",
                                   value: $config.puffsPerDevice,
                                   range: 600...10000,
                                   step: 50,
                                   rangeDescriptionKey: "puffs_per_device_range")
            }

            GlassSection("onboarding_section_cost") {
                DecimalField(titleKey: "device_price_title",
                             placeholderKey: "device_price_placeholder",
                             value: $config.devicePrice)
                InfoTipView(textKey: "device_price_tip")
            }
        }
    }
}

struct RefillableVapeFormView: View {
    @Binding var config: RefillableVapeConfig

    var body: some View {
        VStack(spacing: 24) {
            GlassSection("onboarding_section_consumption") {
                IntegerSliderField(titleKey: "liquid_volume_title",
                                   subtitleKey: "liquid_volume_subtitle",
                                   value: $config.liquidBottleMl,
                                   range: 10...120,
                                   rangeDescriptionKey: "liquid_volume_range")
                IntegerSliderField(titleKey: "nicotine_strength_title",
                                   subtitleKey: "nicotine_strength_subtitle",
                                   value: $config.nicotineMgPerMl,
                                   range: 1...60,
                                   rangeDescriptionKey: "nicotine_strength_range")
                IntegerSliderField(titleKey: "puffs_per_ml_title",
                                   subtitleKey: "puffs_per_ml_subtitle",
                                   value: $config.estimatedPuffsPerMl,
                                   range: 10...30,
                                   rangeDescriptionKey: "puffs_per_ml_range")
            }

            GlassSection("onboarding_section_cost") {
                DecimalField(titleKey: "liquid_price_title",
                             placeholderKey: "liquid_price_placeholder",
                             value: $config.liquidPrice)

                Toggle(isOn: hasCoilPriceBinding) {
                    Text("coil_price_toggle")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .toggleStyle(SwitchToggleStyle(tint: OnboardingTheme.accentStart))

                if config.coilPrice != nil {
                    DecimalOptionalField(titleKey: "coil_price_title",
                                         placeholderKey: "coil_price_placeholder",
                                         value: $config.coilPrice)
                }

                InfoTipView(textKey: "refillable_price_tip")
            }
        }
    }

    private var hasCoilPriceBinding: Binding<Bool> {
        Binding(
            get: { config.coilPrice != nil },
            set: { include in
                config.coilPrice = include ? (config.coilPrice ?? 5) : nil
            }
        )
    }
}

struct HeatedTobaccoFormView: View {
    @Binding var config: HeatedTobaccoConfig

    var body: some View {
        VStack(spacing: 24) {
            GlassSection("onboarding_section_consumption") {
                IntegerSliderField(titleKey: "heated_daily_sticks_title",
                                   subtitleKey: "heated_daily_sticks_subtitle",
                                   value: $config.dailySticks,
                                   range: 1...40,
                                   rangeDescriptionKey: "heated_daily_sticks_range")

                IntegerSliderField(titleKey: "heated_sticks_per_pack_title",
                                   subtitleKey: "heated_sticks_per_pack_subtitle",
                                   value: $config.sticksPerPack,
                                   range: 10...40,
                                   rangeDescriptionKey: "heated_sticks_per_pack_range")
            }

            GlassSection("onboarding_section_cost") {
                DecimalField(titleKey: "heated_pack_price_title",
                             placeholderKey: "heated_pack_price_placeholder",
                             value: $config.packPrice)
            }
        }
    }
}

struct SnusFormView: View {
    @Binding var config: SnusConfig

    var body: some View {
        VStack(spacing: 24) {
            GlassSection("onboarding_section_consumption") {
                IntegerSliderField(titleKey: "snus_daily_title",
                                   subtitleKey: "snus_daily_subtitle",
                                   value: $config.dailyPouches,
                                   range: 1...40,
                                   rangeDescriptionKey: "snus_daily_range")
                IntegerSliderField(titleKey: "snus_per_can_title",
                                   subtitleKey: "snus_per_can_subtitle",
                                   value: $config.pouchesPerCan,
                                   range: 10...40,
                                   rangeDescriptionKey: "snus_per_can_range")
            }

            GlassSection("onboarding_section_cost") {
                DecimalField(titleKey: "snus_can_price_title",
                             placeholderKey: "snus_can_price_placeholder",
                             value: $config.canPrice)
            }
        }
    }
}

// MARK: - Shared components

private struct IntegerSliderField: View {
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey?
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let rangeDescriptionKey: LocalizedStringKey?

    init(titleKey: LocalizedStringKey,
         subtitleKey: LocalizedStringKey? = nil,
         value: Binding<Int>,
         range: ClosedRange<Int>,
         step: Int = 1,
         rangeDescriptionKey: LocalizedStringKey? = nil) {
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self._value = value
        self.range = range
        self.step = step
        self.rangeDescriptionKey = rangeDescriptionKey
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey)
                .font(.headline)
                .foregroundStyle(.white)

            if let subtitleKey {
                Text(subtitleKey)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            HStack {
                Text("\(value)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(OnboardingTheme.accentStart)
                Spacer()
                Text("\(range.lowerBound) - \(range.upperBound)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0.rounded()) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: Double(step))
            .tint(OnboardingTheme.accentStart)

            if let rangeDescriptionKey {
                Text(rangeDescriptionKey)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct DecimalField: View {
    let titleKey: LocalizedStringKey
    let placeholderKey: LocalizedStringKey
    @Binding var value: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey)
                .font(.headline)
                .foregroundStyle(.white)
            TextField(placeholderKey,
                      value: _value.doubleBinding(),
                      format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .glassInputStyle()
        }
    }
}

private struct DecimalOptionalField: View {
    let titleKey: LocalizedStringKey
    let placeholderKey: LocalizedStringKey
    @Binding var value: Decimal?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey)
                .font(.headline)
                .foregroundStyle(.white)
            TextField(placeholderKey,
                      value: _value.optionalDoubleBinding(),
                      format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .glassInputStyle()
        }
    }
}

private struct InfoTipView: View {
    let textKey: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(OnboardingTheme.accentStart)
                .accessibilityHidden(true)
            Text(textKey)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 6)
    }
}

private extension Binding where Value == Decimal {
    func doubleBinding() -> Binding<Double> {
        Binding<Double>(
            get: { NSDecimalNumber(decimal: self.wrappedValue).doubleValue },
            set: { self.wrappedValue = Decimal($0) }
        )
    }
}

private extension Binding where Value == Decimal? {
    func optionalDoubleBinding() -> Binding<Double?> {
        Binding<Double?>(
            get: {
                guard let decimal = self.wrappedValue else { return nil }
                return NSDecimalNumber(decimal: decimal).doubleValue
            },
            set: { newValue in
                if let newValue {
                    self.wrappedValue = Decimal(newValue)
                } else {
                    self.wrappedValue = nil
                }
            }
        )
    }
}
