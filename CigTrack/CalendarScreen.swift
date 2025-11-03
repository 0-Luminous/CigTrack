import SwiftUI
import CoreData

struct CalendarScreen: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var user: User

    @State private var monthAnchor: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDay: DaySelection?

    private var entryType: EntryType { user.product.entryType }
    private var limit: Int { Int(user.dailyLimit) }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                ForEach(daysInMonth, id: \.self) { day in
                    Button {
                        selectedDay = DaySelection(date: day)
                    } label: {
                        CalendarDayCell(date: day,
                                        count: count(for: day),
                                        limit: limit,
                                        isToday: Calendar.current.isDateInToday(day))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(monthTitle)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    shiftMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shiftMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .sheet(item: $selectedDay) { selection in
            DailyDetailSheet(user: user, date: selection.date, entryType: entryType)
        }
    }

    private var daysInMonth: [Date] {
        let range = Calendar.current.range(of: .day, in: .month, for: monthAnchor) ?? 1..<32
        return range.compactMap { day -> Date? in
            var components = Calendar.current.dateComponents([.year, .month], from: monthAnchor)
            components.day = day
            return Calendar.current.date(from: components)
        }
    }

    private func shiftMonth(_ delta: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: delta, to: monthAnchor) else { return }
        monthAnchor = Calendar.current.startOfMonth(for: next)
    }

    private func count(for date: Date) -> Int {
        let service = StatsService(context: context)
        return service.countForDay(user: user, date: date, type: entryType)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: monthAnchor).capitalized
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let count: Int
    let limit: Int
    let isToday: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(dayString)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.headline)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(height: 64)
        .overlay(alignment: .topTrailing) {
            if isToday {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var dayString: String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    private var color: Color {
        if count == 0 { return .secondary }
        if count <= limit { return .green }
        if count <= Int(Double(limit) * 1.25) { return .orange }
        return .red
    }
}

private struct DailyDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var user: User
    let date: Date
    let entryType: EntryType

    @FetchRequest private var entries: FetchedResults<Entry>

    init(user: User, date: Date, entryType: EntryType) {
        self.user = user
        self.date = date
        self.entryType = entryType

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date) as NSDate
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))! as NSDate

        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND createdAt >= %@ AND createdAt < %@ AND type == %d",
                                        user, start, end, entryType.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: true)]
        _entries = FetchRequest(fetchRequest: request, animation: .default)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(formattedDate)) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading) {
                            Text(timeString(for: entry.createdAt ?? Date()))
                                .font(.headline)
                            if entry.cost > 0 {
                                Text(String(format: "%.2f", entry.cost))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Day details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

private struct DaySelection: Identifiable {
    let date: Date
    var id: Date { date }
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        CalendarScreen(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
