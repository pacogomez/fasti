// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "fasti",
    dependencies: [
      .package(url: "https://github.com/jakeheis/SwiftCLI", from: "6.0.0"),
      .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.5.0"),
      .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [

        .executableTarget(
            name: "fasti",
            dependencies: ["SwiftCLI", "SwiftyTextTable", "Rainbow"]),
        .testTarget(
            name: "fastiTests",
            dependencies: ["fasti"]),
    ]
)
