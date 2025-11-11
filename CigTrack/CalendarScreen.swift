import SwiftUI
import CoreData

struct CalendarScreen: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var user: User
    @AppStorage("dashboardBackgroundIndex") private var backgroundIndex: Int = DashboardBackgroundStyle.default.rawValue

    @State private var monthAnchor: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDay: DaySelection?

    private var entryType: EntryType { user.product.entryType }
    private var limit: Int { Int(user.dailyLimit) }
    private var backgroundStyle: DashboardBackgroundStyle {
        DashboardBackgroundStyle(rawValue: backgroundIndex) ?? .default
    }
    private var backgroundGradient: LinearGradient { backgroundStyle.backgroundGradient }
    private var primaryTextColor: Color { backgroundStyle.primaryTextColor }
    private var secondaryTextColor: Color { backgroundStyle.secondaryTextColor }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    yearHeader
                        .padding(.horizontal)

                    MonthSlider(months: monthsOfYear,
                                selection: $monthAnchor,
                                selectedColor: primaryTextColor,
                                unselectedColor: secondaryTextColor)

                    WeekdayHeader(textColor: secondaryTextColor)
                        .padding(.vertical, 8)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .glassEffect(.clear)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                        ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                            if let date = day {
                                Button {
                                    selectedDay = DaySelection(date: date)
                                } label: {
                                    CalendarDayCell(date: date,
                                                    count: count(for: date),
                                                    limit: limit,
                                                    isToday: Calendar.current.isDateInToday(date),
                                                    isInCurrentMonth: Calendar.current.isDate(date, equalTo: monthAnchor, toGranularity: .month),
                                                    labelColor: primaryTextColor)
                                }
                                .buttonStyle(.plain)
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.02))
                                    .frame(height: 84)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                    .glassEffect(.clear)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("")
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: monthAnchor)
        .sheet(item: $selectedDay) { selection in
            DailyDetailSheet(user: user, date: selection.date, entryType: entryType)
        }
    }

    private var yearHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    shiftYear(-1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .padding(20)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            .glassEffect(.clear)
            .accessibilityLabel("Previous year")

            Spacer()

            Text(yearTitle)
                .font(.largeTitle.bold())
                .foregroundStyle(primaryTextColor)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    shiftYear(1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .padding(20)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            .glassEffect(.clear)
            .accessibilityLabel("Next year")
        }
    }

    private var gridDays: [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: monthAnchor) ?? 1..<32

        // All days in the current month
        let monthDays: [Date] = range.compactMap { day -> Date? in
            var components = calendar.dateComponents([.year, .month], from: monthAnchor)
            components.day = day
            return calendar.date(from: components)
        }

        // Number of leading placeholders based on the first weekday in locale
        let firstOfMonth = calendar.startOfMonth(for: monthAnchor)
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        // Fill with trailing placeholders to complete rows (5–6 weeks)
        let total = leading + monthDays.count
        let rows = Int(ceil(Double(total) / 7.0))
        let target = rows * 7
        let trailing = max(0, target - total)

        return Array(repeating: nil, count: leading) + monthDays.map { Optional.some($0) } + Array(repeating: nil, count: trailing)
    }

    private func shiftYear(_ delta: Int) {
        guard let next = Calendar.current.date(byAdding: .year, value: delta, to: monthAnchor) else { return }
        monthAnchor = Calendar.current.startOfMonth(for: next)
    }

    private func count(for date: Date) -> Int {
        let service = StatsService(context: context)
        return service.countForDay(user: user, date: date, type: entryType)
    }

    private var yearTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("y")
        return formatter.string(from: monthAnchor)
    }

    private var monthsOfYear: [Date] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year], from: monthAnchor)
        components.month = 1
        components.day = 1
        let startOfYear = calendar.date(from: components) ?? monthAnchor
        return (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: startOfYear) }
    }

}

private struct CalendarDayCell: View {
    let date: Date
    let count: Int
    let limit: Int
    let isToday: Bool
    let isInCurrentMonth: Bool
    let labelColor: Color

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 30, style: .continuous)

        return VStack(spacing: 8) {
            HStack {
                Text(dayString)
                    .font(.caption)
                    .fontWeight(isToday ? .semibold : .regular)
                    .foregroundStyle(isInCurrentMonth ? labelColor.opacity(0.9) : labelColor.opacity(0.4))
            }

            VStack(spacing: 6) {
                Text("\(count)")
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [color.opacity(0.14), color.opacity(0.28)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Subtle progress bar against limit
                ProgressView(value: min(Double(count), Double(max(limit, 1))), total: Double(max(limit, 1)))
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(color)
                    .scaleEffect(x: 1, y: 0.75, anchor: .center)
            }
        }
        .padding(12)
        .frame(height: 96)
        .background(
            cardShape
                .fill(Color.white.opacity(isInCurrentMonth ? 0.14 : 0.04))
        )
        .overlay(
            cardShape
                .strokeBorder(isToday ? Color.accentColor.opacity(0.9) : Color.white.opacity(0.12), lineWidth: isToday ? 2 : 1)
        )
        .clipShape(cardShape)
        .glassEffect(.clear)
        .shadow(color: .black.opacity(0.25 * (isInCurrentMonth ? 0.15 : 0.05)), radius: 6, x: 0, y: 4)
        .opacity(isInCurrentMonth ? 1.0 : 0.5)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
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

    private var accessibilityText: Text {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateStr = formatter.string(from: date)
        let status: String
        if count == 0 { status = "no entries" }
        else if count <= limit { status = "within limit" }
        else { status = "over limit" }
        return Text("\(dateStr), count \(count), \(status)")
    }
}

// Horizontal slider to jump between months within the selected year
private struct MonthSlider: View {
    let months: [Date]
    @Binding var selection: Date
    let selectedColor: Color
    let unselectedColor: Color

    var body: some View {
        ScrollViewReader { proxy in
            sliderScrollView
                .padding(.vertical, 8)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .glassEffect(.clear)
                .padding(.horizontal)
                .onAppear { scrollToSelection(proxy) }
                .onChange(of: selection) { _, _ in
                    scrollToSelection(proxy)
                }
        }
    }

    private var sliderScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(months.indices, id: \.self) { index in
                    let month = months[index]
                    MonthChip(label: monthLabel(for: month),
                              isSelected: isSelected(month),
                              selectedColor: selectedColor,
                              unselectedColor: unselectedColor,
                              action: { select(month) })
                        .id(index)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: selection, toGranularity: .month)
    }

    private func select(_ date: Date) {
        let month = Calendar.current.startOfMonth(for: date)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            selection = month
        }
    }

    private func scrollToSelection(_ proxy: ScrollViewProxy) {
        let index = Calendar.current.component(.month, from: selection) - 1
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                proxy.scrollTo(index, anchor: .center)
            }
        }
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date).capitalized
    }
}

private struct MonthChip: View {
    let label: String
    let isSelected: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .monospacedDigit()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 52)
                .foregroundStyle(isSelected ? selectedColor : unselectedColor.opacity(0.85))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .overlay(
            Capsule()
                .strokeBorder(borderColor, lineWidth: isSelected ? 1.5 : 1)
        )
        .clipShape(Capsule())
        .glassEffect(.clear)
    }

    private var backgroundColor: Color {
        isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.07)
    }

    private var borderColor: Color {
        isSelected ? Color.white.opacity(0.65) : Color.white.opacity(0.2)
    }
}

// Weekday header, localized and ordered by user’s firstWeekday
private struct WeekdayHeader: View {
    let textColor: Color

    private var symbols: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Safely unwrap symbols with sensible fallback
        let base = formatter.shortStandaloneWeekdaySymbols ?? formatter.shortWeekdaySymbols ?? [
            "Sun","Mon","Tue","Wed","Thu","Fri","Sat"
        ]
        let start = calendar.firstWeekday - 1 // convert to 0-index
        let rotated = Array(base[start...]) + Array(base[..<start])
        return rotated.map { String($0.prefix(2)).uppercased() }
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor.opacity(0.85))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// Removed external accessibility helper to avoid double counting per cell

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
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.clear)
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
