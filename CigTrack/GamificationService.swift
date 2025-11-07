import CoreData

final class GamificationService {
    private let context: NSManagedObjectContext
    private let stats: StatsService
    private lazy var calendar = Calendar.current

    init(context: NSManagedObjectContext) {
        self.context = context
        self.stats = StatsService(context: context)
    }

    static func level(forXP xp: Int64) -> Int {
        max(1, Int(floor(sqrt(Double(xp) / 100.0)) + 1))
    }

    func bootstrapCatalogIfNeeded() {
        achievementCatalog.forEach { _ = createIfNeeded(definition: $0) }
    }

    func onEntryAdded(user: User, at date: Date) {
        // Placeholder for real-time reactions (animations, haptics, etc.)
        _ = stats.countForDay(user: user, date: date, type: user.product.entryType)
    }

    func nightlyRecalc(user: User, date: Date) {
        let type = user.product.entryType
        let count = stats.countForDay(user: user, date: date, type: type)
        let limit = Int(user.dailyLimit)

        var xpGain: Int64 = 0
        var coinsGain: Int64 = 0

        if count <= limit {
            xpGain += 30
            coinsGain += 5
            incrementStreak(for: user)
        } else {
            resetStreak(for: user)
            let delta = max(0, count - limit)
            xpGain += max(5, Int64(15 - delta))
        }

        user.xp += xpGain
        user.coins += coinsGain

        updateAchievements(for: user, date: date)
        context.saveIfNeeded()
    }

    private func incrementStreak(for user: User) {
        let streak = ensureStreak(for: user)
        streak.currentLength += 1
        streak.bestLength = max(streak.bestLength, streak.currentLength)
        streak.updatedAt = Date()
    }

    private func resetStreak(for user: User) {
        let streak = ensureStreak(for: user)
        streak.currentLength = 0
        streak.updatedAt = Date()
    }

    private func ensureStreak(for user: User) -> Streak {
        if let streak = user.streak {
            return streak
        }
        let streak = Streak(context: context)
        streak.id = UUID()
        streak.currentLength = 0
        streak.bestLength = 0
        streak.updatedAt = Date()
        streak.user = user
        return streak
    }

    private func updateAchievements(for user: User, date: Date) {
        achievementCatalog.forEach { definition in
            let achievement = createIfNeeded(definition: definition)
            let userAchievement = fetchUserAchievement(user: user, achievement: achievement) ?? {
                let ua = UserAchievement(context: context)
                ua.id = UUID()
                ua.user = user
                ua.achievement = achievement
                ua.progress = 0
                return ua
            }()

            let newProgress: Int64
            switch definition.kind {
            case .streak:
                newProgress = Int64(user.streak?.bestLength ?? 0)
            case .daysWithinLimit:
                newProgress = progressForDaysWithinLimit(user: user)
            case .totalSaved:
                newProgress = estimatedMoneySaved(user: user)
            }

            userAchievement.progress = max(userAchievement.progress, newProgress)
            if userAchievement.achievedAt == nil && userAchievement.progress >= achievement.threshold {
                userAchievement.achievedAt = date
                user.coins += 20
                user.xp += 100
            }
        }
    }

    private func createIfNeeded(definition: AchievementDefinition) -> Achievement {
        if let existing = fetchAchievement(code: definition.code) {
            return existing
        }
        let achievement = Achievement(context: context)
        achievement.id = UUID()
        achievement.code = definition.code
        achievement.title = NSLocalizedString(definition.title, comment: "achievement title")
        achievement.descText = NSLocalizedString(definition.description, comment: "achievement description")
        achievement.icon = definition.icon
        achievement.threshold = definition.threshold
        achievement.kind = definition.kind.rawValue
        return achievement
    }

    private func fetchAchievement(code: String) -> Achievement? {
        let req: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "code == %@", code)
        return try? context.fetch(req).first
    }

    private func fetchUserAchievement(user: User, achievement: Achievement) -> UserAchievement? {
        let req: NSFetchRequest<UserAchievement> = UserAchievement.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "user == %@ AND achievement == %@", user, achievement)
        return try? context.fetch(req).first
    }

    private func progressForDaysWithinLimit(user: User) -> Int64 {
        let type = user.product.entryType
        let streak = ensureStreak(for: user)
        let withinLimitDays = streak.currentLength
        let stats = StatsService(context: context)
        let totals = stats.totalsForLastDays(user: user, days: 30, type: type)
        let goodDays = totals.filter { $0.value <= Int(user.dailyLimit) }.count
        return max(Int64(withinLimitDays), Int64(goodDays))
    }

    func estimatedMoneySaved(user: User) -> Int64 {
        // Estimate savings using user-provided pack cost when available.
        let type = user.product.entryType
        let stats = StatsService(context: context)
        let totals = stats.totalsForLastDays(user: user, days: 30, type: type)
        let average = totals.values.reduce(0, +) / max(1, totals.count)

        let inferredCostPerUnit: Double
        if type == .cig, user.packSize > 0, user.packCost > 0 {
            inferredCostPerUnit = user.packCost / Double(user.packSize)
        } else {
            inferredCostPerUnit = type == .cig ? 15.0 : 8.0
        }

        let baseline = Double(user.dailyLimit) * inferredCostPerUnit
        let actual = Double(average) * inferredCostPerUnit
        let saved = max(0, baseline - actual)
        return Int64(saved * 30)
    }

    private struct AchievementDefinition {
        let code: String
        let title: String
        let description: String
        let icon: String
        let threshold: Int64
        let kind: AchievementKind
    }

    private let achievementCatalog: [AchievementDefinition] = [
        AchievementDefinition(code: "first_day",
                              title: "First Step",
                              description: "Track at least one day to begin your journey.",
                              icon: "flame",
                              threshold: 1,
                              kind: .daysWithinLimit),
        AchievementDefinition(code: "week_control",
                              title: "Control x7",
                              description: "Stay within your limit for 7 days in a row.",
                              icon: "calendar",
                              threshold: 7,
                              kind: .streak),
        AchievementDefinition(code: "savings_1000",
                              title: "Savings 1000",
                              description: "Save 1000 currency units compared to your baseline.",
                              icon: "banknote",
                              threshold: 1000,
                              kind: .totalSaved)
    ]
}
