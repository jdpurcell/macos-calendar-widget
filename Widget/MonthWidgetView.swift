import AppIntents
import SwiftUI
import WidgetKit

struct MonthWidgetView: View {
    let entry: MonthEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var defaultMargins

    private var isSmall: Bool { family == .systemSmall }
    private var isLarge: Bool { family == .systemLarge }
    private var titleSize: CGFloat { isLarge ? 16 : 12 }
    private var daySize: CGFloat { isLarge ? 15 : 11 }
    private var todayCircle: CGFloat { isLarge ? 30 : 18 }
    private var controlIconSize: CGFloat { isLarge ? 12 : 10 }
    private var controlButtonSize: CGFloat { isLarge ? 23 : 19 }

    private var contentMargins: EdgeInsets {
        // Keep the system's actual margins wherever a tighter layout isn't needed.
        switch family {
        case .systemSmall:
            return EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        case .systemMedium:
            return EdgeInsets(top: 8, leading: defaultMargins.leading,
                              bottom: 8, trailing: defaultMargins.trailing)
        default:
            return defaultMargins
        }
    }

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
            monthGrid
        }
        .padding(contentMargins)
    }

    private var monthGrid: some View {
        ZStack {
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

            HStack(spacing: 0) {
                pageZone(delta: -1, label: "Previous month")
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                pageZone(delta: 1, label: "Next month")
            }
        }
    }

    private var header: some View {
        HStack(spacing: isLarge ? 8 : (isSmall ? 3 : 5)) {
            Text(isSmall ? entry.shortTitle : entry.title)
                .font(.system(size: titleSize, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.leading, isSmall ? 5 : 0)

            Spacer(minLength: 2)

            if !isSmall {
                headerButton(delta: -12, systemName: "chevron.left.2", label: "Previous year")
            }
            headerButton(delta: -1, systemName: "chevron.left", label: "Previous month")

            Button(intent: GoToTodayIntent()) {
                Image(systemName: "smallcircle.filled.circle")
                    .font(.system(size: controlIconSize, weight: .semibold))
                    .frame(width: controlButtonSize, height: controlButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(entry.isCurrentMonth ? 0.4 : 1)
            .accessibilityLabel("Current month")

            headerButton(delta: 1, systemName: "chevron.right", label: "Next month")
            if !isSmall {
                headerButton(delta: 12, systemName: "chevron.right.2", label: "Next year")
            }
        }
        .font(.system(size: isLarge ? 13 : 11, weight: .semibold))
        .foregroundStyle(.secondary)
    }

    private func headerButton(delta: Int, systemName: String, label: String) -> some View {
        Button(intent: ShiftMonthIntent(delta: delta)) {
            Image(systemName: systemName)
                .font(.system(size: controlIconSize, weight: .semibold))
                .frame(width: controlButtonSize, height: controlButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func pageZone(delta: Int, label: String) -> some View {
        Button(intent: ShiftMonthIntent(delta: delta)) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(entry.weekdays.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(size: isLarge ? 10 : 9, weight: .semibold))
                    .foregroundStyle(.blue)
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
