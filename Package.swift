// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ClassBell",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ClassBellCore", targets: ["ClassBellCore"]),
        .executable(name: "ClassBell", targets: ["ClassBellApp"])
    ],
    targets: [
        .target(name: "ClassBellCore"),
        .executableTarget(
            name: "ClassBellApp",
            dependencies: ["ClassBellCore"]
        ),
        .testTarget(
            name: "ClassBellCoreTests",
            dependencies: ["ClassBellCore"]
        )
    ]
)
