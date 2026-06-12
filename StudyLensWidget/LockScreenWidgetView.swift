import SwiftUI
import WidgetKit

struct LockScreenWidgetView: View {
    let entry: StudyWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                Text("\(entry.streak)")
                    .font(.headline.weight(.bold))
            }
        }
    }
}
