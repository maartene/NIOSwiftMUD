// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NIOSwiftMUD",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "NIOSwiftMUD",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Crypto", package: "swift-crypto")
            ]),
        .testTarget(
            name: "NIOSwiftMUDTests",
            dependencies: ["NIOSwiftMUD"]),
    ]
)
