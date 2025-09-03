// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MKSwiftBXPSeriesSlathf",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "MKSwiftBXPSeriesSlathf",
            // 明确指定为动态库，并要求库演进
            type: .dynamic,
            targets: ["MKSwiftBXPSeriesSlathf"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKBaseSwiftModule.git", from: "1.0.14"),
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKSwiftBeaconXCustomUI.git", from: "1.0.10"),
        .package(url: "https://github.com/MOKO-iOS-Base-Library/MKSwiftBleModule.git", from: "1.0.12"),
        .package(url: "https://github.com/itsmeichigo/DateTimePicker.git", from: "2.5.3")
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
            resources: [.process("Assets")],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("IOS14_OR_LATER"),
                .enableUpcomingFeature("LibraryEvolution"),
                // 或者使用这个（根据Swift版本选择）
                .enableExperimentalFeature("BuildServerLibraryEvolution")
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("iconv")
            ]
        ),
        .testTarget(
            name: "MKSwiftBXPSeriesSlathfTests",
            dependencies: ["MKSwiftBXPSeriesSlathf"]
        )
    ]
)
