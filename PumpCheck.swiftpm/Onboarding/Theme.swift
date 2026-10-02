import SwiftUI

struct Theme {
    static let pitchBlack = Color(red: 12/255.0, green: 26/255.0, blue: 39/255.0) // #0c1a27
    static let darkCoffee = Color(red: 0/255.0, green: 0/255.0, blue: 0/255.0) // #000000
    static let neonIce = Color(red: 107/255.0, green: 208/255.0, blue: 250/255.0) // #6bd0fa
    static let deepBlue = Color(red: 107/255.0, green: 208/255.0, blue: 250/255.0) // override with cyan
    static let textBoxBlue = Color(red: 0/255.0, green: 0/255.0, blue: 0/255.0) // #000000
    static let paleSky = Color(red: 216/255.0, green: 238/255.0, blue: 253/255.0) // #d8eefd
    static let taupeGrey = Color(red: 100/255.0, green: 88/255.0, blue: 83/255.0)

    static let bgGradient = LinearGradient(
        colors: [pitchBlack, pitchBlack],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardBackground = textBoxBlue
    
    static let accent = deepBlue
    static let textPrimary = paleSky
    static let textSecondary = paleSky.opacity(0.7)
}

struct PumpTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Theme.textBoxBlue)
            .cornerRadius(16)
            .foregroundColor(Theme.paleSky)
            .environment(\.colorScheme, .dark)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    func pumpButtonStyle(isPrimary: Bool = true) -> some View {
        self
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(isPrimary ? Theme.pitchBlack : Theme.paleSky)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(isPrimary ? Theme.accent : Theme.cardBackground)
            .cornerRadius(16)
            .shadow(color: isPrimary ? Theme.accent.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
    }
}
