// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MKSwiftBXPSeriesSlathf",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "MKSwiftBXPSeriesSlathf",
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
                "MKBaseSwiftModule",
                "MKSwiftBeaconXCustomUI",
                "MKSwiftBleModule",
                "DateTimePicker"
            ],
            path: "Sources",
            resources: [.process("Assets")],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "MKSwiftBXPSeriesSlathfTests",
            dependencies: ["MKSwiftBXPSeriesSlathf"]
        )
    ]
)
