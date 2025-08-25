// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MKSwiftBXPSeriesSlathf",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MKSwiftBXPSeriesSlathf",
            targets: ["MKSwiftBXPSeriesSlathf"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKBaseSwiftModule.git", .upToNextMajor(from: "1.0.14")),
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKSwiftBeaconXCustomUI.git", .upToNextMajor(from: "1.0.10")),
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKSwiftBleModule.git", .upToNextMajor(from: "1.0.12")),
        .package(url: "https://github.com/itsmeichigo/DateTimePicker.git", .upToNextMajor(from: "2.5.3"))
    ],
    targets: [
        .target(
            name: "MKSwiftBXPSeriesSlathf",
            dependencies: [
                .product(name: "MKBaseSwiftModule", package: "MKBaseSwiftModule"),
                .product(name: "MKSwiftBeaconXCustomUI", package: "MKSwiftBeaconXCustomUI"),
                .product(name: "MKSwiftBleModule", package: "MKSwiftBleModule"),
                .product(name: "DateTimePicker", package: "DateTimePicker")
            ],
            path: "Sources",
            resources: [
                .process("Assets")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("IOS14_OR_LATER")  // 添加编译标志
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("iconv")
            ]
        ),
        .testTarget(
            name: "MKSwiftBXPSeriesSlathfTests",
            dependencies: ["MKSwiftBXPSeriesSlathf"])
    ]
)
