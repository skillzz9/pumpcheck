with open("PumpCheck.swiftpm/Package.swift", "r") as f:
    content = f.read()

target1 = """,
        .package(url: "https://github.com/joogps/IrregularGradient.git", from: "2.1.0")"""
replacement1 = ""

target2 = """,
                .product(name: "IrregularGradient", package: "IrregularGradient")"""
replacement2 = ""

content = content.replace(target1, replacement1)
content = content.replace(target2, replacement2)

with open("PumpCheck.swiftpm/Package.swift", "w") as f:
    f.write(content)

print("Patched Package.swift")
