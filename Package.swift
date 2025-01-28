// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LgiccCapacitorVoiceRecorder",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "LgiccCapacitorVoiceRecorder",
            targets: ["CapacitorVoiceRecorderPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "CapacitorVoiceRecorderPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
            ],
            path: "ios/Sources/CapacitorVoiceRecorderPlugin"),
        .testTarget(
            name: "CapacitorVoiceRecorderPluginTests",
            dependencies: ["CapacitorVoiceRecorderPlugin"],
            path: "ios/Tests/CapacitorVoiceRecorderPluginTests")
    ]
)
