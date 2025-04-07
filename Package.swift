// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScienceTokyoPortalKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ScienceTokyoPortalKit",
            targets: ["ScienceTokyoPortalKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.3.0"),
        .package(url: "https://github.com/SomeRandomiOSDev/CBORCoding.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ScienceTokyoPortalKit",
            dependencies: ["Kanna", "CBORCoding"]
        ),
        .testTarget(
            name: "ScienceTokyoPortalKitTests",
            dependencies: ["ScienceTokyoPortalKit"],
            resources: [
                .process("HTML"),
            ]
        ),
    ]
)
