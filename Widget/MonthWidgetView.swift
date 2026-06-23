import SwiftUI
import WidgetKit

struct MonthWidgetView: View {
    let entry: MonthEntry

    @Environment(\.widgetFamily) private var family

    private var isLarge: Bool { family == .systemLarge }
    private var titleSize: CGFloat { isLarge ? 16 : 13 }
    private var daySize: CGFloat { isLarge ? 15 : 12 }
    private var todayCircle: CGFloat { isLarge ? 30 : 21 }

    /// Split the flat 42-cell list into weeks of 7.
    private var weeks: [[DayCell]] {
        stride(from: 0, to: entry.cells.count, by: 7).map {
            Array(entry.cells[$0 ..< min($0 + 7, entry.cells.count)])
        }
    }

    var body: some View {
        VStack(spacing: isLarge ? 8 : 5) {
            header
            weekdayRow
            // Week rows expand to share all remaining height -> grid fills the widget.
            VStack(spacing: 0) {
                ForEach(weeks.indices, id: \.self) { i in
                    HStack(spacing: 0) {
                        ForEach(weeks[i]) { cell in
                            dayView(cell)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text(entry.title)
                .font(.system(size: titleSize, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            Button(intent: ShiftMonthIntent(delta: -1)) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Button(intent: GoToTodayIntent()) {
                Image(systemName: "smallcircle.filled.circle")
            }
            .buttonStyle(.plain)
            .opacity(entry.isCurrentMonth ? 0.4 : 1)

            Button(intent: ShiftMonthIntent(delta: 1)) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: isLarge ? 13 : 11, weight: .semibold))
        .foregroundStyle(.secondary)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(entry.weekdays.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(size: isLarge ? 10 : 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayView(_ cell: DayCell) -> some View {
        Text("\(cell.day)")
            .font(.system(size: daySize, weight: cell.isToday ? .bold : .regular))
            .foregroundStyle(dayColor(cell))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if cell.isToday {
                    Circle()
                        .fill(Color.red)
                        .frame(width: todayCircle, height: todayCircle)
                }
            }
    }

    private func dayColor(_ cell: DayCell) -> Color {
        if cell.isToday { return .white }
        return cell.isInCurrentMonth ? .primary : Color.secondary.opacity(0.35)
    }
}
