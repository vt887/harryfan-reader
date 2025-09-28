// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HarryfanReader",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "HarryFan Reader",
            targets: ["HarryFan Reader"],
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "HarryFan Reader",
            dependencies: [],
            path: "harryfan-reader",
            exclude: [
                "HarryFanReader.entitlements",
                "Info.plist",
            ],
            resources: [
                .copy("Fonts"),
                .process("Assets.xcassets"),
                .process("Preview Content/Preview Assets.xcassets"),
            ],
        ),
    ],
)
