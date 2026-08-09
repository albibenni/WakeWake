// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WakeWake",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WakeWake",
            targets: ["WakeWake"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WakeWake",
            dependencies: [],
            path: "WakeWake",
            exclude: [
                "App/Info.plist",
                "Entitlements/WakeWake.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "WakeWakeTests",
            dependencies: ["WakeWake"],
            path: "WakeWakeTests"
        )
    ]
)
