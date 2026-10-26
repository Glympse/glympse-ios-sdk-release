# glympse-ios-sdk-release
Repository is used to host the iOS Core SDK dependency

These releases are accessible using CocoaPods https://cocoapods.org/

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

## Usage

In your project's podfile add the GlympseApi pod

```
target 'YourApp' do
  pod 'GlympseAPI'
  ...
end
```

See https://guides.cocoapods.org/using/using-cocoapods.html for the latest instructions on how to install and update pods
