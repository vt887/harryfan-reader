// swift-tools-version: 5.9
import PackageDescription

let baseName = "HarryFanReader"
let productName = "HarryFan Reader"

let package = Package(
    name: baseName,
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: productName, // HarryFan Reader
            targets: [baseName]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.5.0"),
    ],
    targets: [
        .executableTarget(
            name: baseName, // HarryFanReader
            dependencies: [],
            path: "Sources/HarryFanReader",
            exclude: [
                "HarryFanReader.entitlements",
                "Info.plist",
            ],
            resources: [
                .copy("Fonts"),
                .process("Assets.xcassets"),
                .process("Preview Content/Preview Assets.xcassets"),
            ]
        ),
        .testTarget(
            name: "\(baseName)Tests", // HarryFanReaderTests
            dependencies: [.target(name: baseName), "Nimble", "Quick"],
            path: "Tests/HarryFanReaderTests"
        ),
    ]
)
