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
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.108.279/GlympseKit.zip",
            checksum: "31721b8b53e97266d46e06925c2a2b7365497c63848efc50a889460504e7927f"
        ),
        .binaryTarget(
            name: "GlympsePrivateAPI",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.108.279/GlympsePrivateAPI.zip",
            checksum: "8933103185eaa3e2be5db7a5910c3988cb67a4fc48284db475048c0791e86623"
        ),
    ]
)
