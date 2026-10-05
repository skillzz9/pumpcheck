import sys

with open("PumpCheck.swiftpm/Onboarding/Theme.swift", "r") as f:
    content = f.read()

old_colors = """    static let pitchBlack = Color(red: 12/255.0, green: 26/255.0, blue: 39/255.0) // #0c1a27
    static let darkCoffee = Color(red: 0/255.0, green: 0/255.0, blue: 0/255.0) // #000000
    static let neonIce = Color(red: 107/255.0, green: 208/255.0, blue: 250/255.0) // #6bd0fa
    static let deepBlue = Color(red: 107/255.0, green: 208/255.0, blue: 250/255.0) // override with cyan
    static let textBoxBlue = Color(red: 0/255.0, green: 0/255.0, blue: 0/255.0) // #000000
    static let paleSky = Color(red: 216/255.0, green: 238/255.0, blue: 253/255.0) // #d8eefd
    static let taupeGrey = Color(red: 100/255.0, green: 88/255.0, blue: 83/255.0)"""

new_colors = """    // Palette 5
    static let pitchBlack = Color(red: 27/255.0, green: 38/255.0, blue: 50/255.0) // #1B2632 (Abyssal Anchorfish Blue)
    static let darkCoffee = Color(red: 163/255.0, green: 81/255.0, blue: 57/255.0) // #A35139 (Truffle Trouble)
    static let neonIce = Color(red: 255/255.0, green: 177/255.0, blue: 98/255.0) // #FFB162 (Burning Flame)
    static let deepBlue = Color(red: 255/255.0, green: 177/255.0, blue: 98/255.0) // #FFB162 (Burning Flame)
    static let textBoxBlue = Color(red: 44/255.0, green: 59/255.0, blue: 77/255.0) // #2C3B4D (Blue Fantastic)
    static let paleSky = Color(red: 238/255.0, green: 233/255.0, blue: 223/255.0) // #EEE9DF (Palladian)
    static let taupeGrey = Color(red: 201/255.0, green: 193/255.0, blue: 177/255.0) // #C9C1B1 (Oatmeal)"""

content = content.replace(old_colors, new_colors)

with open("PumpCheck.swiftpm/Onboarding/Theme.swift", "w") as f:
    f.write(content)

