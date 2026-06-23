import WidgetKit
import Foundation

struct MonthEntry: TimelineEntry {
    let date: Date
    let title: String
    let weekdays: [String]
    let cells: [DayCell]
    let isCurrentMonth: Bool
}

struct Provider: TimelineProvider {
    private func makeEntry() -> MonthEntry {
        let offset = WidgetStore.monthOffset
        let monthStart = MonthGrid.month(forOffset: offset)
        return MonthEntry(
            date: Date(),
            title: MonthGrid.title(for: monthStart),
            weekdays: MonthGrid.weekdaySymbols(),
            cells: MonthGrid.cells(for: monthStart),
            isCurrentMonth: offset == 0
        )
    }

    func placeholder(in context: Context) -> MonthEntry { makeEntry() }

    func getSnapshot(in context: Context, completion: @escaping (MonthEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh after midnight so the "today" highlight stays accurate.
        let cal = Calendar.current
        let nextMidnight = cal.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}
