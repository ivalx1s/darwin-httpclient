// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "darwin-httpclient",
	platforms: [
		.iOS(.v13),
		.watchOS(.v6),
		.macOS(.v11),
        .tvOS(.v13),
	],
    products: [
        .library(
            name: "HttpClient",
            targets: ["HttpClient"]
		),
    ],
    targets: [
        .target(
            name: "HttpClient",
            dependencies: [],
			path: "Sources"
		),
        .testTarget(
            name: "HttpClientTests",
            dependencies: ["HttpClient"],
            path: "Tests"
        )
    ]
)
