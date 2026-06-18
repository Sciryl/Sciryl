import SwiftUI

/// Single source of truth for Warden's visual language. Every color, radius,
/// and font used by a view should come from here, so re-skinning the app
/// later only means editing this file.
struct Theme {
    // MARK: Colors
    static let background = Color(hex: "0E0F0E")
    static let background2 = Color(hex: "16181A")
    static let background3 = Color(hex: "1E2123")

    static let mainText = Color(hex: "F2EFE8")
    static let dimText = Color(hex: "A8A8A0")
    static let faintText = Color(hex: "5A5C58")

    static let ruleColor = Color(hex: "2A2D2E")

    static let accentGreen = Color(hex: "A8D257")
    static let deepGreen = Color(hex: "7FA63F")
    static let accentOrange = Color(hex: "E87722")
    static let deepOrange = Color(hex: "C25E13")
    static let accentRed = Color(hex: "E14A3C")
    static let deepRed = Color(hex: "B53528")
    static let silver = Color(hex: "C9CCC9")

    // MARK: Corner radii
    static let windowCornerRadius: CGFloat = 10
    static let containerCornerRadius: CGFloat = 4
    static let buttonCornerRadius: CGFloat = 2

    // MARK: Fonts
    /// These reference custom font families by name. If the corresponding
    /// font files haven't been added to the app target, the system silently
    /// substitutes the default font, so the app still renders correctly
    /// either way. See the project README for how to add the real files.
    struct Fonts {
        static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .custom("Barlow Condensed", size: size).weight(weight)
        }

        static func mono(size: CGFloat) -> Font {
            .custom("JetBrains Mono", size: size)
        }
    }
}
