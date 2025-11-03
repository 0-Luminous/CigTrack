import SwiftUI
import CoreData
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var user: User?
    @Published var shouldShowOnboarding = false

    private let context: NSManagedObjectContext
    private let gamification: GamificationService

    init(context: NSManagedObjectContext) {
        self.context = context
        self.gamification = GamificationService(context: context)
        loadUser()
    }

    func loadUser() {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first {
            user = existing
            shouldShowOnboarding = false
        } else {
            shouldShowOnboarding = true
        }
    }

    func completeOnboarding(with data: OnboardingData) {
        let newUser = User(context: context)
        newUser.id = UUID()
        newUser.createdAt = Date()
        newUser.productType = data.productType.rawValue
        newUser.dailyLimit = Int32(data.dailyLimit)
        newUser.displayName = data.displayName
        newUser.coins = 0
        newUser.xp = 0

        gamification.bootstrapCatalogIfNeeded()
        context.saveIfNeeded()

        user = newUser
        shouldShowOnboarding = false
    }

    func resetOnboarding() {
        user = nil
        shouldShowOnboarding = true
    }
}

struct OnboardingData {
    var productType: ProductType = .cigarette
    var dailyLimit: Int = 10
    var displayName: String = ""
    var prefersSignInWithApple: Bool = false
}
