// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GlympseAPI",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GlympseKit",
            targets: ["GlympseKit", "GlympsePrivateAPI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "GlympseKit",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.109.301/GlympseKit.zip",
            checksum: "c1f923d63c744022ee64fa648dc5fce8527f5c123b4d052eea87218a4e946693"
        ),
        .binaryTarget(
            name: "GlympsePrivateAPI",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.109.301/GlympsePrivateAPI.zip",
            checksum: "d6e3c7c70b0e2aec2714adb8eb9a4bd65104fc6bb82b9afbdd8dfec852be9d7b"
        ),
    ]
)
