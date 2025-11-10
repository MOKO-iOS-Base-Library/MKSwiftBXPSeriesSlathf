// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MKSwiftBXPSeriesSlathf",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MKSwiftBXPSeriesSlathf",
            // 移除 type: .dynamic 或改为 .static
            targets: ["MKSwiftBXPSeriesSlathf"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKBaseSwiftModule.git", from: "1.0.14"),
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKSwiftCustomUI.git", from: "1.0.0"),
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKSwiftBeaconXCustomUI.git", from: "1.0.11"),
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKSwiftBleModule.git", from: "1.0.12"),
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKSwiftUILibrary.git", from: "1.0.0"),
        .package(url: "https://github.com/itsmeichigo/DateTimePicker.git", from: "2.5.3"),
    ],
    targets: [
        .target(
            name: "MKSwiftBXPSeriesSlathf",
            dependencies: [
                .product(name: "MKBaseSwiftModule", package: "MKBaseSwiftModule"),
                .product(name: "MKSwiftCustomUI", package: "MKSwiftCustomUI"),
                .product(name: "MKSwiftBeaconXCustomUI", package: "MKSwiftBeaconXCustomUI"),
                .product(name: "MKSwiftBleModule", package: "MKSwiftBleModule"),
                .product(name: "MKSwiftUILibrary", package: "MKSwiftUILibrary"),
                .product(name: "DateTimePicker", package: "DateTimePicker"),
            ],
            path: "Sources",
            resources: [.process("Assets")],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
            ]
        ),
        .testTarget(
            name: "MKSwiftBXPSeriesSlathfTests",
            dependencies: ["MKSwiftBXPSeriesSlathf"]
        )
    ]
)
