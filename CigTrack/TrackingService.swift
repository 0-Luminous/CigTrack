import CoreData

final class TrackingService {
    private let context: NSManagedObjectContext
    private let statsService: StatsService
    private let gamification: GamificationService

    init(context: NSManagedObjectContext) {
        self.context = context
        self.statsService = StatsService(context: context)
        self.gamification = GamificationService(context: context)
    }

    func addEntry(for user: User, type: EntryType, cost: Double? = nil, date: Date = Date()) {
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.createdAt = date
        entry.type = type.rawValue
        entry.cost = resolvedCost(for: user, explicitCost: cost, type: type)
        entry.user = user

        statsService.bumpDailyCount(for: user, at: date, type: type)
        gamification.onEntryAdded(user: user, at: date)
        context.saveIfNeeded()
    }

    private func resolvedCost(for user: User, explicitCost: Double?, type: EntryType) -> Double {
        if let explicitCost {
            return explicitCost
        }

        guard type == .cig else {
            return 0
        }

        let packSize = max(Int(user.packSize), 0)
        let packCost = user.packCost
        guard packSize > 0, packCost > 0 else {
            return 0
        }
        return packCost / Double(packSize)
    }
}
