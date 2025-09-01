// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TxtViewer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "TxtViewer",
            targets: ["TxtViewer"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TxtViewer",
            dependencies: [],
            path: "TxtViewer",
            resources: [
                .process("vdu.8x16.raw"),
                .process("Assets.xcassets"),
                .process("Preview Content/Preview Assets.xcassets")
            ]
        )
    ]
)
