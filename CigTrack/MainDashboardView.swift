import SwiftUI
import CoreData
import Combine
import UIKit

struct MainDashboardView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var user: User

    @AppStorage("dashboardBackgroundIndex") private var backgroundIndex: Int = DashboardBackgroundStyle.default.rawValue

    @State private var todayCount: Int = 0
    @State private var nextSuggestedDate: Date?
    @State private var showSettings = false
    @State private var now = Date()
    @State private var weekEntryCounts: [Date: Int] = [:]

    // Hold-to-log interaction state
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var holdTimerCancellable: AnyCancellable?
    @State private var holdCompleted = false
    @State private var hapticTrigger: Int = 0
    @State private var breathingScale: CGFloat = 1.0
    @State private var didStartBreathing = false
    @State private var breathingTask: Task<Void, Never>?
    @State private var holdHapticCancellable: AnyCancellable?
    @State private var holdHapticGenerator = UIImpactFeedbackGenerator(style: .heavy)

    private var entryType: EntryType { user.product.entryType }
    private var dailyLimit: Int { max(Int(user.dailyLimit), 0) }
    private var backgroundStyle: DashboardBackgroundStyle {
        DashboardBackgroundStyle(rawValue: backgroundIndex) ?? .default
    }

    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let holdDuration: TimeInterval = 1.1
    private let holdTick: TimeInterval = 0.02

    private static let nextTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale.current
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    holdButton

                    VStack(spacing: 8) {
                        Text(remainingLabel)
                            .font(.system(size: 16, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(backgroundStyle.primaryTextColor)

                        Text("🚬 \(nextEntryLabel)".uppercased())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(backgroundStyle.secondaryTextColor)
                    }

                    Spacer()

                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(user: user)
            }
            .onAppear {
                now = Date()
                refreshToday(reference: now)
                startBreathingAnimation()
            }
            .onDisappear {
                didStartBreathing = false
                breathingTask?.cancel()
                breathingTask = nil
                stopHoldHaptics()
            }
            .onReceive(clock) { time in
                let previousDay = Calendar.current.startOfDay(for: now)
                let currentDay = Calendar.current.startOfDay(for: time)
                now = time
                if currentDay != previousDay {
                    refreshToday(reference: time)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

private extension MainDashboardView {
    var holdButton: some View {
        ZStack {
            
            Circle()
                .fill(Color.white)
                .scaleEffect(max(holdProgress, 0.001))
                .opacity(holdProgress > 0 ? 0.9 : 0)
                .blendMode(.plusLighter)

            Circle()
                .glassEffect()
                
            Text("\(todayCount)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(backgroundStyle.circleTextColor)
                .allowsHitTesting(false)
        }
        .frame(width: 260, height: 260)
        .scaleEffect(buttonScale)
        .animation(.easeInOut(duration: 0.12), value: isHolding)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 80, pressing: { pressing in
            if pressing {
                startHold()
            } else {
                stopHoldIfNeeded()
            }
        }, perform: {
            completeHold()
        })
        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.95), trigger: hapticTrigger)
    }
}

// MARK: - Computed Values

private extension MainDashboardView {
    var buttonScale: CGFloat {
        let holdScale: CGFloat = isHolding ? 0.95 : 1.0
        return breathingScale * holdScale
    }

    var backgroundGradient: LinearGradient {
        backgroundStyle.backgroundGradient
    }

    var circleGradient: RadialGradient {
        backgroundStyle.circleGradient
    }

    var remainingLabel: String {
        let remaining = max(dailyLimit - todayCount, 0)
        return String(format: NSLocalizedString("%@ LEFT TODAY: %d/%d", comment: "Remaining entries label"),
                      entryTypeLabel,
                      remaining,
                      dailyLimit)
    }

    var nextEntryLabel: String {
        guard dailyLimit > 0 else {
            return NSLocalizedString("Next at: anytime", comment: "No limit fallback")
        }

        guard let nextSuggestedDate else {
            return NSLocalizedString("Next at: now", comment: "No entries yet fallback")
        }

        if nextSuggestedDate <= now {
            return NSLocalizedString("Next at: now", comment: "Ready now fallback")
        }

        let formatted = Self.nextTimeFormatter.string(from: nextSuggestedDate)
        return String(format: NSLocalizedString("Next at: %@", comment: "Next entry time"), formatted)
    }

    var entryTypeLabel: String {
        switch entryType {
        case .cig: return NSLocalizedString("CIGARETTES", comment: "cigarettes label")
        case .puff: return NSLocalizedString("PUFFS", comment: "puffs label")
        }
    }

    var trialStatusText: String {
        guard let createdAt = user.createdAt else {
            return NSLocalizedString("TRIAL ENDS SOON", comment: "Trial fallback")
        }
        let trialDurationHours: Double = 72
        let elapsedSeconds = max(now.timeIntervalSince(createdAt), 0)
        let elapsedHours = elapsedSeconds / 3600
        let remaining = max(Int(trialDurationHours - floor(elapsedHours)), 0)
        if remaining == 0 {
            return NSLocalizedString("TRIAL ENDED", comment: "Trial ended label")
        }
        return String(format: NSLocalizedString("TRIAL ENDS IN %d HOURS", comment: "Trial countdown label"), remaining)
    }

    var weekDays: [WeekDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        return (0..<7).compactMap { offset -> WeekDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let number = calendar.component(.day, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let label = Self.weekdayFormatter.string(from: date)
            let key = calendar.startOfDay(for: date)
            let count = weekEntryCounts[key] ?? 0
            return WeekDay(date: date,
                           displayNumber: "\(number)",
                           displayLabel: isToday ? NSLocalizedString("Today", comment: "today label") : label,
                           isToday: isToday,
                           count: count,
                           limit: dailyLimit)
        }
    }
}

// MARK: - Week Strip Helpers

private extension MainDashboardView {
    func dayBackground(for day: WeekDay) -> Color {
        if day.isToday {
            return Color.white
        }
        if day.count == 0 {
            return Color.white.opacity(0.18)
        }
        return Color.white.opacity(0.24)
    }

    func dayRingColor(for day: WeekDay) -> Color {
        let ratio = day.progress
        if ratio >= 1.0 {
            return Color.red.opacity(0.9)
        } else if ratio >= 0.8 {
            return Color.orange.opacity(0.9)
        } else {
            return Color.green.opacity(0.95)
        }
    }
}

// MARK: - Hold Interaction

private extension MainDashboardView {
    func startBreathingAnimation() {
        guard !didStartBreathing else { return }
        didStartBreathing = true
        breathingScale = 1.0
        breathingTask?.cancel()
        breathingTask = Task {
            var increasing = true
            while !Task.isCancelled {
                let target: CGFloat = increasing ? 1.05 : 0.97
                increasing.toggle()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 2.2)) {
                        breathingScale = target
                    }
                }
                try? await Task.sleep(nanoseconds: UInt64(2.2 * 1_000_000_000))
            }
        }
    }

    func startHold() {
        guard holdTimerCancellable == nil else { return }
        holdCompleted = false
        isHolding = true
        holdProgress = 0
        startHoldHaptics()

        let step = holdTick / holdDuration
        holdTimerCancellable = Timer.publish(every: holdTick, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(.linear(duration: holdTick)) {
                    holdProgress = min(holdProgress + step, 1)
                }
                if holdProgress >= 1 {
                    stopHoldTimer()
                }
            }
    }

    func stopHoldIfNeeded() {
        guard !holdCompleted else { return }
        cancelHold()
    }

    func cancelHold() {
        stopHoldTimer()
        isHolding = false
        stopHoldHaptics()
        if holdProgress > 0 {
            withAnimation(.easeOut(duration: 0.2)) {
                holdProgress = 0
            }
        }
    }

    func completeHold() {
        holdCompleted = true
        stopHoldTimer()
        isHolding = false
        stopHoldHaptics()

        withAnimation(.easeOut(duration: 0.25)) {
            holdProgress = 1
        }

        logEntry()
        hapticTrigger += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.3)) {
                holdProgress = 0
            }
            holdCompleted = false
        }
    }

    func stopHoldTimer() {
        holdTimerCancellable?.cancel()
        holdTimerCancellable = nil
    }

    func startHoldHaptics() {
        holdHapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
        holdHapticGenerator.prepare()
        holdHapticCancellable?.cancel()
        holdHapticCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                holdHapticGenerator.impactOccurred(intensity: 0.9)
            }
    }

    func stopHoldHaptics() {
        holdHapticCancellable?.cancel()
        holdHapticCancellable = nil
    }
}

// MARK: - Actions

private extension MainDashboardView {
    func logEntry() {
        let tracker = TrackingService(context: context)
        tracker.addEntry(for: user, type: entryType)
        refreshToday(reference: Date())
    }

    func refreshToday(reference: Date) {
        let stats = StatsService(context: context)
        todayCount = stats.countForDay(user: user, date: reference, type: entryType)
        weekEntryCounts = fetchWeekCounts(stats: stats, anchor: reference)
        nextSuggestedDate = calculateNextSuggestedDate()
    }

    func calculateNextSuggestedDate() -> Date? {
        guard dailyLimit > 0 else { return nil }

        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "user == %@ AND type == %d",
                                        user, entryType.rawValue)

        guard
            let lastEntry = try? context.fetch(request).first,
            let createdAt = lastEntry.createdAt
        else {
            return nil
        }

        let interval = 24 * 60 * 60 / Double(max(dailyLimit, 1))
        return createdAt.addingTimeInterval(interval)
    }

    func fetchWeekCounts(stats: StatsService, anchor: Date) -> [Date: Int] {
        let calendar = Calendar.current
        let dayAnchor = calendar.startOfDay(for: anchor)
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dayAnchor)) else {
            return [:]
        }

        var result: [Date: Int] = [:]
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let count = stats.countForDay(user: user, date: date, type: entryType)
            result[calendar.startOfDay(for: date)] = count
        }
        return result
    }
}

// MARK: - Models

private struct WeekDay: Identifiable {
    let date: Date
    let displayNumber: String
    let displayLabel: String
    let isToday: Bool
    let count: Int
    let limit: Int

    var id: Date { date }

    var progress: Double {
        guard limit > 0 else { return 0 }
        return Double(count) / Double(limit)
    }
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        MainDashboardView(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
