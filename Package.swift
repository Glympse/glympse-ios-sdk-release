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
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.108.272/GlympseKit.zip",
            checksum: "248f71e48c248b85dab9be3f860b730a652926d9d90f836d32cfbef98e425950"
        ),
        .binaryTarget(
            name: "GlympsePrivateAPI",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.108.272/GlympsePrivateAPI.zip",
            checksum: "04db7a402b774c5b379ee8e189ead04e3d62072b9c7b613d9e9b52b4e6c1ab6c"
        ),
    ]
)
