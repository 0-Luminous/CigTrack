import SwiftUI
import CoreData

struct MainDashboardView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appViewModel: AppViewModel
    @ObservedObject var user: User

    @State private var todayCount: Int = 0
    @State private var motivationText: String = ""
    @State private var showSettings = false

    private var entryType: EntryType { user.product.entryType }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    bigActionButton
                    progressSection
                    streakCard
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    NavigationLink {
                        CalendarScreen(user: user)
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }

                    NavigationLink {
                        StatsScreen(user: user)
                    } label: {
                        Label("Stats", systemImage: "chart.bar.xaxis")
                    }

                    NavigationLink {
                        AchievementsScreen(user: user)
                    } label: {
                        Label("Achievements", systemImage: "medal")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(user: user)
            }
        }
        .onAppear(perform: refreshToday)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hello, \(user.displayName ?? "Adventurer")")
                .font(.title.bold())
            Text(motivationText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: updateMotivationText)
    }

    private var bigActionButton: some View {
        Button(action: addEntry) {
            Text(user.product.buttonLabel)
                .font(.system(size: 28, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.accentColor))
                .foregroundStyle(.white)
                .shadow(radius: 8, y: 6)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: todayCount)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let limit = Int(user.dailyLimit)
            HStack {
                Text("Today: \(todayCount) / \(limit)")
                    .font(.headline)
                Spacer()
                Text("Lvl \(user.level)")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
            }
            ProgressView(value: Double(todayCount), total: Double(max(limit, 1)))
                .progressViewStyle(.linear)
                .tint(progressColor)
            Text(progressFootnote)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var streakCard: some View {
        let current = Int(user.streak?.currentLength ?? 0)
        let best = Int(user.streak?.bestLength ?? 0)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Streak")
                    .font(.headline)
                Text("Current: \(current) days")
                Text("Best: \(best) days")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: current >= best ? "flame.fill" : "flame")
                .font(.title)
                .foregroundStyle(.orange)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
    }

    private func addEntry() {
        let tracker = TrackingService(context: context)
        tracker.addEntry(for: user, type: entryType)
        refreshToday()
    }

    private func refreshToday() {
        let stats = StatsService(context: context)
        todayCount = stats.countForDay(user: user, date: Date(), type: entryType)
    }

    private func updateMotivationText() {
        let phrases = [
            "Every calm breath earns you XP.",
            "Keep the streak alive!",
            "Less today means more freedom tomorrow."
        ]
        motivationText = phrases.randomElement() ?? ""
    }

    private var progressRatio: Double {
        let limit = max(Int(user.dailyLimit), 1)
        return Double(todayCount) / Double(limit)
    }

    private var progressColor: Color {
        switch progressRatio {
        case ..<0.8: return .green
        case ..<1.0: return .orange
        default: return .red
        }
    }

    private var progressFootnote: String {
        switch progressRatio {
        case ..<0.8:
            return NSLocalizedString("Nice pace! Stay under your limit to earn bonus XP tonight.", comment: "progress footnote")
        case ..<1.0:
            return NSLocalizedString("Close to the limit. A mindful pause keeps the streak burning.", comment: "progress footnote")
        default:
            return NSLocalizedString("Limit exceeded. Tomorrow is a fresh start!", comment: "progress footnote")
        }
    }
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        MainDashboardView(user: user)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
