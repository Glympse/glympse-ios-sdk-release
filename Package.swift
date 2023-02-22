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
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.106.241/GlympseKit.zip",
            checksum: "940bf549992d55439105cbfa5a15d7305602a4f39a1448859579de736dfe7b68"
        ),
        .binaryTarget(
            name: "GlympsePrivateAPI",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.106.241/GlympsePrivateAPI.zip",
            checksum: "c4919898c06ad90daa8b1c1a76c395c739c48a5f34d8a441a4a1532bb3cb71a1"
        ),
    ]
)
