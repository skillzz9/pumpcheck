// swift-tools-version: 5.8
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "PumpCheck",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "PumpCheck",
            targets: ["AppModule"],
            bundleIdentifier: "com.pumpcheck.app",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .weights),
            accentColor: .presetColor(.cyan),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/EmergeTools/Pow", from: "1.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "Pow", package: "Pow"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: ".",
            sources: ["Onboarding", "PumpCheckApp.swift"],
            resources: [
                .process("GoogleService-Info.plist")
            ]
        )
    ]
)
