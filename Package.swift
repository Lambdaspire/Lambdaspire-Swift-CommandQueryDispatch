// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "LambdaspireSwiftCommandQueryDispatch",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LambdaspireSwiftCommandQueryDispatch",
            targets: ["LambdaspireSwiftCommandQueryDispatch"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Lambdaspire/Lambdaspire-Swift-Abstractions",
            from: "2.0.0"),
        .package(
            url: "https://github.com/Lambdaspire/Lambdaspire-Swift-DependencyResolution",
            from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LambdaspireSwiftCommandQueryDispatch",
            dependencies: [
                .product(name: "LambdaspireAbstractions", package: "Lambdaspire-Swift-Abstractions")
            ]),
        .testTarget(
            name: "LambdaspireSwiftCommandQueryDispatchTests",
            dependencies: [
                "LambdaspireSwiftCommandQueryDispatch",
                .product(name: "LambdaspireDependencyResolution", package: "Lambdaspire-Swift-DependencyResolution")
            ]),
    ]
)
