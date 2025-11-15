import SwiftUI

struct SettingsMethodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let selectedMethod: NicotineMethod
    let onMethodSelected: (NicotineMethod) -> Void

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 20)]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(NicotineMethod.allCases) { method in
                            Button {
                                select(method)
                            } label: {
                                MethodCardView(method: method, isSelected: method == selectedMethod)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle("Choose Method")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick the nicotine method you want to track.")
                .font(.title3.weight(.semibold))
            Text("This keeps reminders, stats, and budgeting focused on the right product.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(colors: [
            Color(.secondarySystemBackground),
            Color(.systemBackground)
        ], startPoint: .top, endPoint: .bottom)
    }

    private func select(_ method: NicotineMethod) {
        onMethodSelected(method)
        dismiss()
    }
}

#Preview {
    SettingsMethodPickerView(selectedMethod: .cigarettes) { _ in }
        .preferredColorScheme(.dark)
}
