// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fasti",
    dependencies: [
      .package(url: "https://github.com/jakeheis/SwiftCLI", from: "6.0.0"),
      .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "fasti",
            dependencies: ["SwiftCLI", "SwiftyTextTable"]),
        .testTarget(
            name: "fastiTests",
            dependencies: ["fasti"]),
    ]
)