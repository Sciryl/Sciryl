import SwiftUI

/// Centralized button styling. Swapping the app's look later means editing
/// these three styles rather than hunting through every view.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default).weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Theme.accentGreen.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Theme.background3.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(Theme.mainText)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonCornerRadius)
                    .stroke(Theme.ruleColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body).weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Theme.accentRed.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(Theme.mainText)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
    }
}

extension View {
    /// Applies the standard "card" container background + radius used for
    /// sheets, popovers, and grouped panels throughout the app.
    func wardenContainerStyle() -> some View {
        self
            .background(Theme.background2)
            .clipShape(RoundedRectangle(cornerRadius: Theme.containerCornerRadius))
    }
}
