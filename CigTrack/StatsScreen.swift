import SwiftUI
import CoreData
import Charts

struct StatsScreen: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var user: User

    @State private var weeklyData: [DailyPoint] = []
    @State private var average: Double = 0
    @State private var savedEstimate: Double = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Chart(weeklyData) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(Color.accentColor)

                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(LinearGradient(colors: [.accentColor.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

                metricsSection

                streakSection
            }
            .padding(24)
        }
        .navigationTitle("Stats")
        .onAppear(perform: refresh)
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatRow(title: "Average per day", value: String(format: "%.1f", average))
            StatRow(title: "Daily limit", value: "\(user.dailyLimit)")
            StatRow(title: "Estimated savings / month", value: String(format: "%.0f", savedEstimate))
            StatRow(title: "Level", value: "\(user.level)")
            StatRow(title: "XP", value: "\(user.xp)")
            StatRow(title: "Coins", value: "\(user.coins)")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.headline)
            HStack {
                StatRow(title: "Current", value: "\(user.streak?.currentLength ?? 0)")
                StatRow(title: "Best", value: "\(user.streak?.bestLength ?? 0)")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func refresh() {
        let stats = StatsService(context: context)
        let entryType = user.product.entryType
        let totals = stats.totalsForLastDays(user: user, days: 7, type: entryType)
        weeklyData = totals.map { DailyPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }

        if !weeklyData.isEmpty {
            average = Double(weeklyData.map(\.count).reduce(0, +)) / Double(weeklyData.count)
        } else {
            average = 0
        }

        let gamification = GamificationService(context: context)
        savedEstimate = Double(gamification.estimatedMoneySaved(user: user))
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}

private struct DailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        StatsScreen(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
