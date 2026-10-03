with open("PumpCheck.swiftpm/Package.swift", "r") as f:
    content = f.read()

target1 = """    dependencies: [
        .package(url: "https://github.com/EmergeTools/Pow", from: "1.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],"""
replacement1 = """    dependencies: [
        .package(url: "https://github.com/EmergeTools/Pow", from: "1.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/joogps/IrregularGradient.git", from: "2.1.0")
    ],"""

target2 = """            dependencies: [
                .product(name: "Pow", package: "Pow"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],"""
replacement2 = """            dependencies: [
                .product(name: "Pow", package: "Pow"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "IrregularGradient", package: "IrregularGradient")
            ],"""

content = content.replace(target1, replacement1)
content = content.replace(target2, replacement2)

with open("PumpCheck.swiftpm/Package.swift", "w") as f:
    f.write(content)

print("Patched Package.swift")
