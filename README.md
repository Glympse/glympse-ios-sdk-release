# glympse-ios-sdk-release
Repository is used to host the iOS Core SDK dependency

These releases are distributed with Swift Package Manager. Release binaries are attached to this repository's
[GitHub releases](https://github.com/Glympse/glympse-ios-sdk-release/releases).

## Integration guide

A step-by-step integration guide for the Core SDK on iOS is in [`integration/`](integration/). It is written to be read
by developers and by AI coding agents. It covers the `GlympseKit` (Swift and Objective-C) API, which is available as the
`GlympseKit` product of this repository's Swift package.

- [`integration/AGENTS.md`](integration/AGENTS.md): installation, capabilities and Info.plist requirements, the exact
  start-up call order (the SDK creates an anonymous user on first start, after consent), lifecycle and threading rules,
  the main flows for sending and viewing Glympses, push notifications and common pitfalls.
- [`integration/llms-full.txt`](integration/llms-full.txt): a reference outline of the API (managers, events, constants
  and models).

To have your coding agent use the guide, copy both files into the root of your app's repository (keep them together, as
`AGENTS.md` refers to `llms-full.txt`).

## Usage (Swift Package Manager)

### Xcode

1. In your project choose File > Add Package Dependencies.
2. Enter the package URL `https://github.com/Glympse/glympse-ios-sdk-release`.
3. Choose the dependency rule "Up to Next Major Version" starting from the latest release (see the
   [releases page](https://github.com/Glympse/glympse-ios-sdk-release/releases)).
4. Add the `GlympseKit` product to your app target.
5. In your Swift files `import GlympseKit`.

### Package.swift

If your app or library is itself a Swift package, add the dependency and the product to your target:

```swift
dependencies: [
    .package(url: "https://github.com/Glympse/glympse-ios-sdk-release", from: "<latest release>")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "GlympseKit", package: "glympse-ios-sdk-release")
        ]
    )
]
```

The package declares iOS 12 as its minimum deployment target. The `GlympseKit` product wraps the C++ core library, which is included automatically.

See https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app for Apple's instructions on
adding, updating and removing package dependencies.
