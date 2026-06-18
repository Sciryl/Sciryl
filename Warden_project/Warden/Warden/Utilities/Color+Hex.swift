import SwiftUI
import AppKit

extension Color {
    /// Builds a Color from a "RRGGBB" or "#RRGGBB" hex string. Falls back to
    /// mid-gray if the string can't be parsed so a bad value never crashes.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgbValue)

        guard cleaned.count == 6 else {
            self = Color(red: 0.5, green: 0.5, blue: 0.5)
            return
        }

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255
        self = Color(red: r, green: g, blue: b)
    }

    /// Converts the color back to a "RRGGBB" hex string, used when saving a
    /// tag's custom color chosen from a ColorPicker.
    func toHex() -> String {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
