// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftDisplayLink",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftDisplayLink",
            targets: ["SwiftDisplayLink"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftDisplayLink",
            //No Need to define Sources here as every file that is present under this predefined location `[PackageRoot]/Sources/[TargetName]` is treated as its source file.
            dependencies: []),
        .testTarget(
            name: "SwiftDisplayLinkTests",
            //No Need to define Sources here as every file that is present under this predefined location `[PackageRoot]/Tests/[TargetName]Tests` is treated as its test file.
            dependencies: ["SwiftDisplayLink"]),
    ]
)
