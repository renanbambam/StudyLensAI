import WidgetKit
import SwiftUI

@main
struct StudyLensWidgetBundle: WidgetBundle {
    var body: some Widget {
        StudyLensHomeWidget()
        StudyLensLockScreenWidget()
    }
}

struct StudyLensHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StudyLensHomeWidget", provider: StudyWidgetProvider()) { entry in
            StudyWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cards Due Today")
        .description("Shows the deck with the most due cards and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StudyLensLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StudyLensLockScreenWidget", provider: StudyWidgetProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Study Streak")
        .description("Your daily study streak at a glance.")
        .supportedFamilies([.accessoryCircular])
    }
}
