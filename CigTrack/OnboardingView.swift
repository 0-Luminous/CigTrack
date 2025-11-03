import SwiftUI
import CoreData

struct OnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var step = 0
    @State private var form = OnboardingData()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text(titleForStep)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)

                contentForStep

                Spacer()

                HStack {
                    if step > 0 {
                        Button(action: previousStep) {
                            Text("Back")
                        }
                    }
                    Spacer()
                    Button(action: nextStep) {
                        Text(step == steps.count - 1 ? "Start" : "Next")
                            .font(.headline)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.accentColor.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .disabled(!isStepValid)
                }
            }
            .padding(24)
            .animation(.easeInOut, value: step)
            .navigationTitle("PuffQuest")
        }
    }

    private var steps: [OnboardingStep] { OnboardingStep.allCases }

    private var titleForStep: String {
        steps[step].title
    }

    @ViewBuilder
    private var contentForStep: some View {
        switch steps[step] {
        case .welcome:
            VStack(alignment: .leading, spacing: 12) {
                Text("Track, reduce, and celebrate every win on your smoke-free quest.")
                Text("Stay within your limits to earn XP, coins, and unlock new themes.")
                    .foregroundStyle(.secondary)
            }
        case .product:
            VStack(spacing: 16) {
                ForEach(ProductType.allCases) { type in
                    Button {
                        form.productType = type
                    } label: {
                        HStack {
                            Text(type.title)
                                .font(.headline)
                            Spacer()
                            if form.productType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                    }
                    .buttonStyle(.plain)
                }
            }
        case .limit:
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Limit: \(form.dailyLimit)")
                    .font(.title2.bold())
                Slider(value: Binding(
                    get: { Double(form.dailyLimit) },
                    set: { form.dailyLimit = Int($0) }),
                       in: 2...40,
                       step: 1)
                Text("Keep the number realistic to stay motivated.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .profile:
            VStack(spacing: 16) {
                TextField("Display name", text: $form.displayName)
                    .textFieldStyle(.roundedBorder)
                Toggle("Use Sign in with Apple (optional)", isOn: $form.prefersSignInWithApple)
                    .toggleStyle(.switch)
                    .disabled(true) // placeholder for real integration
                    .foregroundStyle(.secondary)
                Text("Local profile is always available. Link Apple ID later in settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var isStepValid: Bool {
        switch steps[step] {
        case .welcome: return true
        case .product: return true
        case .limit: return form.dailyLimit > 0
        case .profile: return !form.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func nextStep() {
        if step < steps.count - 1 {
            step += 1
        } else {
            appViewModel.completeOnboarding(with: form)
        }
    }

    private func previousStep() {
        step = max(0, step - 1)
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case product
    case limit
    case profile

    var title: String {
        switch self {
        case .welcome: return NSLocalizedString("Welcome to PuffQuest", comment: "onboarding step")
        case .product: return NSLocalizedString("Choose your track", comment: "onboarding step")
        case .limit: return NSLocalizedString("Set a daily limit", comment: "onboarding step")
        case .profile: return NSLocalizedString("Create your profile", comment: "onboarding step")
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
