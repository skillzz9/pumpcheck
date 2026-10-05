import SwiftUI

struct Theme {
    // Palette 5
    static let pitchBlack = Color(red: 27/255.0, green: 38/255.0, blue: 50/255.0) // #1B2632 (Abyssal Anchorfish Blue)
    static let darkCoffee = Color(red: 163/255.0, green: 81/255.0, blue: 57/255.0) // #A35139 (Truffle Trouble)
    static let neonIce = Color(red: 255/255.0, green: 177/255.0, blue: 98/255.0) // #FFB162 (Burning Flame)
    static let deepBlue = Color(red: 255/255.0, green: 177/255.0, blue: 98/255.0) // #FFB162 (Burning Flame)
    static let textBoxBlue = Color(red: 44/255.0, green: 59/255.0, blue: 77/255.0) // #2C3B4D (Blue Fantastic)
    static let paleSky = Color(red: 238/255.0, green: 233/255.0, blue: 223/255.0) // #EEE9DF (Palladian)
    static let taupeGrey = Color(red: 201/255.0, green: 193/255.0, blue: 177/255.0) // #C9C1B1 (Oatmeal)

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
