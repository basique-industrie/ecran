// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Ecran",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(name: "Ecran", targets: ["Ecran"]),
        .executable(name: "EcranTests", targets: ["EcranTests"]),
    ],
    targets: [
        .target(
            name: "Domain",
            path: "Sources/Domain",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "WindowGeometry",
            dependencies: [
                "Domain",
            ],
            path: "Sources/WindowGeometry",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "Infrastructure",
            dependencies: [
                "Domain",
                "WindowGeometry",
            ],
            path: "Sources/Infrastructure",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "EcranCore",
            dependencies: [
                "Domain",
                "WindowGeometry",
                "Infrastructure",
            ],
            path: "Sources/Ecran",
            exclude: [
                "Info.plist",
                "Ecran.entitlements",
                "Resources/PrivacyInfo.xcprivacy",
                "Resources/Ecran.icns",
                "Resources/EcranAppIcon.png",
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"], .when(configuration: .debug)),
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "Ecran",
            dependencies: [
                "EcranCore",
            ],
            path: "Sources/EcranApp",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "EcranTests",
            dependencies: [
                "EcranCore",
                "Domain",
                "WindowGeometry",
                "Infrastructure",
            ],
            path: "Tests/EcranTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
