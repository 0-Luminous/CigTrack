import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appViewModel: AppViewModel
    @ObservedObject var user: User

    @AppStorage("dashboardBackgroundIndex") private var backgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @State private var selectedProduct: ProductType = .cigarette
    @State private var dailyLimit: Double = 10
    @State private var accentColor: Color = .accentColor

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display name", text: Binding(
                        get: { user.displayName ?? "" },
                        set: { user.displayName = $0 }
                    ))
                }

                Section("Tracking") {
                    Picker("Product type", selection: $selectedProduct) {
                        ForEach(ProductType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    Stepper(value: $dailyLimit, in: 1...60, step: 1) {
                        Text("Daily limit: \(Int(dailyLimit))")
                    }
                }

                Section("Appearance") {
                    ColorPicker("Accent color", selection: $accentColor, supportsOpacity: false)
                    backgroundSelectionRow
                }

                Section {
                    Button(role: .destructive) {
                        appViewModel.resetOnboarding()
                        dismiss()
                    } label: {
                        Text("Reset onboarding")
                    }
                } footer: {
                    Text("You can re-run the onboarding to change more details or start a new journey.")
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
        }
    }

    private func synchronizeForm() {
        selectedProduct = ProductType(rawValue: user.productType) ?? .cigarette
        dailyLimit = Double(user.dailyLimit)
    }

    private func save() {
        user.productType = selectedProduct.rawValue
        user.dailyLimit = Int32(dailyLimit)
        context.saveIfNeeded()
        dismiss()
    }
}

private extension SettingsView {
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
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        SettingsView(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
