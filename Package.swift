// swift-tools-version:5.5

import PackageDescription
import Foundation

// holos fork: let consumers that never use DFP / Recaptcha (e.g. the macOS Foundry runner app)
// exclude those iOS-only packages by setting STYTCH_EXCLUDE_DFP=1 in the build environment.
//
// Why: SwiftPM downloads every binary artifact in the resolved graph regardless of platform, so the
// RecaptchaEnterprise xcframework (dl.google.com) gets fetched even for a macOS-only build that never
// links it (the products below are `.when(platforms: [.iOS])`). That download throttles badly on CI.
// StytchCore already guards all DFP/Recaptcha use behind `#if canImport(...)`, so excluding the
// packages compiles cleanly. No effect unless the flag is set — iOS/visionOS consumers (holos-capture)
// resolve exactly as before.
let excludeDFP = ProcessInfo.processInfo.environment["STYTCH_EXCLUDE_DFP"] == "1"

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/marmelroy/PhoneNumberKit", from: "4.1.4"),
    .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2"),
]
var stytchCoreDependencies: [Target.Dependency] = [
    .product(name: "SwiftyJSON", package: "SwiftyJSON"),
]
if !excludeDFP {
    packageDependencies += [
        .package(url: "https://github.com/GoogleCloudPlatform/recaptcha-enterprise-mobile-sdk", from: "18.8.1"),
        .package(url: "https://github.com/stytchauth/stytch-ios-dfp.git", from: "1.0.4"),
    ]
    stytchCoreDependencies += [
        .product(name: "RecaptchaEnterprise", package: "recaptcha-enterprise-mobile-sdk", condition: .when(platforms: [.iOS])),
        .product(name: "StytchDFP", package: "stytch-ios-dfp", condition: .when(platforms: [.iOS])),
    ]
}

let package = Package(
    name: "Stytch",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "StytchCore", targets: ["StytchCore"]),
        .library(name: "StytchUI", targets: ["StytchUI"]),
    ],
    dependencies: packageDependencies,
    targets: [
        .target(
            name: "StytchUI",
            dependencies: [
                .target(name: "StytchCore"),
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .target(
            name: "StytchCore",
            dependencies: stytchCoreDependencies,
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(name: "StytchCoreTests", dependencies: ["StytchCore"]),
        .testTarget(name: "StytchUIUnitTests", dependencies: ["StytchCore", "StytchUI"]),
    ]
)
