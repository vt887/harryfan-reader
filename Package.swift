// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HarryfanReader",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "HarryfanReader",
            targets: ["HarryfanReader"],
            ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "HarryfanReader",
            dependencies: [],
            path: "harryfan-reader",
            exclude: [
                "HarryFanReader.entitlements",
                "Info.plist"
            ],
            resources: [
                .copy("Fonts"),
                .process("Assets.xcassets"),
                .process("Preview Content/Preview Assets.xcassets"),
            ]
        )
    ]
)
