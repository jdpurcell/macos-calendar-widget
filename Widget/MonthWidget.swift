import WidgetKit
import SwiftUI

struct MonthCalendarWidget: Widget {
    let kind = "MonthCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MonthWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Calendar")
        .description("Navigate months from Notification Center, like the Windows taskbar calendar.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct CalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthCalendarWidget()
    }
}
