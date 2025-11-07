import SwiftUI

struct CigarettesFormView: View {
    @Binding var config: CigarettesConfig

    var body: some View {
        Section(header: Text("onboarding_section_consumption")) {
            IntegerField(titleKey: "cigarettes_per_day_title",
                         subtitleKey: "cigarettes_per_day_subtitle",
                         value: $config.cigarettesPerDay,
                         rangeDescriptionKey: "cigarettes_per_day_range")
            IntegerField(titleKey: "cigarettes_per_pack_title",
                         subtitleKey: "cigarettes_per_pack_subtitle",
                         value: $config.cigarettesPerPack,
                         rangeDescriptionKey: "cigarettes_per_pack_range")
        }
        Section(header: Text("onboarding_section_cost")) {
            DecimalField(titleKey: "pack_price_title",
                         placeholderKey: "pack_price_placeholder",
                         value: $config.packPrice)
            InfoTipView(textKey: "pack_price_tip")
        }
    }
}

struct DisposableVapeFormView: View {
    @Binding var config: DisposableVapeConfig

    var body: some View {
        Section(header: Text("onboarding_section_consumption")) {
            IntegerField(titleKey: "puffs_per_device_title",
                         subtitleKey: "puffs_per_device_subtitle",
                         value: $config.puffsPerDevice,
                         rangeDescriptionKey: "puffs_per_device_range")
        }

        Section(header: Text("onboarding_section_cost")) {
            DecimalField(titleKey: "device_price_title",
                         placeholderKey: "device_price_placeholder",
                         value: $config.devicePrice)
            InfoTipView(textKey: "device_price_tip")
        }
    }
}

struct RefillableVapeFormView: View {
    @Binding var config: RefillableVapeConfig

    var body: some View {
        Section(header: Text("onboarding_section_consumption")) {
            IntegerField(titleKey: "liquid_volume_title",
                         subtitleKey: "liquid_volume_subtitle",
                         value: $config.liquidBottleMl,
                         rangeDescriptionKey: "liquid_volume_range")
            IntegerField(titleKey: "nicotine_strength_title",
                         subtitleKey: "nicotine_strength_subtitle",
                         value: $config.nicotineMgPerMl,
                         rangeDescriptionKey: "nicotine_strength_range")
            IntegerField(titleKey: "puffs_per_ml_title",
                         subtitleKey: "puffs_per_ml_subtitle",
                         value: $config.estimatedPuffsPerMl,
                         rangeDescriptionKey: "puffs_per_ml_range")
        }

        Section(header: Text("onboarding_section_cost")) {
            DecimalField(titleKey: "liquid_price_title",
                         placeholderKey: "liquid_price_placeholder",
                         value: $config.liquidPrice)

            Toggle(isOn: hasCoilPriceBinding) {
                Text("coil_price_toggle")
            }

            if config.coilPrice != nil {
                DecimalOptionalField(titleKey: "coil_price_title",
                                     placeholderKey: "coil_price_placeholder",
                                     value: $config.coilPrice)
            }

            InfoTipView(textKey: "refillable_price_tip")
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
        Section(header: Text("onboarding_section_consumption")) {
            IntegerField(titleKey: "heated_daily_sticks_title",
                         subtitleKey: "heated_daily_sticks_subtitle",
                         value: $config.dailySticks,
                         rangeDescriptionKey: "heated_daily_sticks_range")

            IntegerField(titleKey: "heated_sticks_per_pack_title",
                         subtitleKey: "heated_sticks_per_pack_subtitle",
                         value: $config.sticksPerPack,
                         rangeDescriptionKey: "heated_sticks_per_pack_range")
        }

        Section(header: Text("onboarding_section_cost")) {
            DecimalField(titleKey: "heated_pack_price_title",
                         placeholderKey: "heated_pack_price_placeholder",
                         value: $config.packPrice)
        }
    }
}

struct SnusFormView: View {
    @Binding var config: SnusConfig

    var body: some View {
        Section(header: Text("onboarding_section_consumption")) {
            IntegerField(titleKey: "snus_daily_title",
                         subtitleKey: "snus_daily_subtitle",
                         value: $config.dailyPouches,
                         rangeDescriptionKey: "snus_daily_range")
            IntegerField(titleKey: "snus_per_can_title",
                         subtitleKey: "snus_per_can_subtitle",
                         value: $config.pouchesPerCan,
                         rangeDescriptionKey: "snus_per_can_range")
        }

        Section(header: Text("onboarding_section_cost")) {
            DecimalField(titleKey: "snus_can_price_title",
                         placeholderKey: "snus_can_price_placeholder",
                         value: $config.canPrice)
        }
    }
}

// MARK: - Shared components

private struct IntegerField: View {
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey?
    @Binding var value: Int
    let rangeDescriptionKey: LocalizedStringKey?

    init(titleKey: LocalizedStringKey,
         subtitleKey: LocalizedStringKey? = nil,
         value: Binding<Int>,
         rangeDescriptionKey: LocalizedStringKey? = nil) {
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self._value = value
        self.rangeDescriptionKey = rangeDescriptionKey
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(.headline)
            if let subtitleKey {
                Text(subtitleKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            if let rangeDescriptionKey {
                Text(rangeDescriptionKey)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(.headline)
            TextField(placeholderKey, value: _value.doubleBinding(), format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct DecimalOptionalField: View {
    let titleKey: LocalizedStringKey
    let placeholderKey: LocalizedStringKey
    @Binding var value: Decimal?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(.headline)
            TextField(placeholderKey, value: _value.optionalDoubleBinding(), format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct InfoTipView: View {
    let textKey: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(textKey)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
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
