// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "FluvialUsers",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.6.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "6.3.0"),
        .package(name: "GraphQLKit", url: "https://github.com/alexsteinerde/graphql-kit.git", from: "2.4.0"),
        .package(name: "GraphiQLVapor", url: "https://github.com/alexsteinerde/graphiql-vapor.git", from: "2.2.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Redis", package: "redis"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "SotoSES", package: "soto"),
                .product(name: "SotoIAM", package: "soto"),
                "GraphQLKit",
                "GraphiQLVapor"
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
