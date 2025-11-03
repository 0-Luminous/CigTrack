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
        entry.cost = cost ?? 0
        entry.user = user

        statsService.bumpDailyCount(for: user, at: date, type: type)
        gamification.onEntryAdded(user: user, at: date)
        context.saveIfNeeded()
    }
}
