import SwiftUI

/// Typography tokens. Built on Dynamic Type text styles so the app scales
/// with the user's accessibility settings.
extension Font {

    static let screenTitle = Font.title2.weight(.bold)
    static let cardFront = Font.title3.weight(.semibold)
    static let cardBack = Font.body
    static let statValue = Font.system(.title, design: .rounded).weight(.bold)
    static let statLabel = Font.caption
    static let badge = Font.caption2.weight(.semibold)
}
