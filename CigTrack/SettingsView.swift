import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appViewModel: AppViewModel
    @ObservedObject var user: User

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

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        SettingsView(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
