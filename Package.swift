// swift-tools-version: 5.9
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
                "Info.plist",
            ],
            resources: [
                .process("vdu.8x16.raw"),
                .process("Assets.xcassets"),
                .process("Preview Content/Preview Assets.xcassets"),
                .process("Info.plist"),
            ],
        ),
    ],
)
