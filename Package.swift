// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZapDPI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ZapDPI",
            targets: ["ZapDPI"]),
    ],
    targets: [
        .target(
            name: "ZapDPI",
            dependencies: [],
            path: "ZapDPI",
            exclude: ["Info.plist", "ZapDPI.entitlements"]),
    ]
)
