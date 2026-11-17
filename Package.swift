// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ZapDPI",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "ZapDPI",
            targets: ["ZapDPI"]
        ),
    ],
    targets: [
        .target(
            name: "ZapDPI"
        ),
    ],
    swiftLanguageModes: [.v5]
)
