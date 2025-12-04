//
//  CigTrackTests.swift
//  CigTrackTests
//
//  Created by Yan on 4/11/25.
//

import Testing
import CoreData
@testable import CigTrack

@MainActor
struct CigTrackTests {

    @Test func statsServiceBumpsDailyCount() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let user = makeUser(in: context, product: .cigarette, limit: 5)
        let service = StatsService(context: context)
        let date = Date()

        service.bumpDailyCount(for: user, at: date, type: .cig)
        context.saveIfNeeded()

        let count = service.countForDay(user: user, date: date, type: .cig)
        #expect(count == 1)
    }

    @Test func gamificationRewardsWithinLimit() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let user = makeUser(in: context, product: .cigarette, limit: 5)
        let stats = StatsService(context: context)
        let gamification = GamificationService(context: context)
        let today = Date()

        (0..<3).forEach { _ in stats.bumpDailyCount(for: user, at: today, type: .cig) }
        gamification.nightlyRecalc(user: user, date: today)

        #expect(user.xp == 30)
        #expect(user.coins == 5)
        #expect(user.streak?.currentLength == 1)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        (0..<7).forEach { _ in stats.bumpDailyCount(for: user, at: tomorrow, type: .cig) }
        gamification.nightlyRecalc(user: user, date: tomorrow)

        #expect(user.streak?.currentLength == 0)
        #expect(user.xp > 30)
    }

    private func makeUser(in context: NSManagedObjectContext, product: ProductType, limit: Int) -> User {
        let user = User(context: context)
        user.id = UUID()
        user.createdAt = Date()
        user.productType = product.rawValue
        user.dailyLimit = Int32(limit)
        user.displayName = "Tester"
        user.coins = 0
        user.xp = 0
        return user
    }
}
