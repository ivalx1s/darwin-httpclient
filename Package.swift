// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "darwin-httpclient",
	platforms: [
		.iOS(.v13),
		.watchOS(.v8),
		.macOS(.v12),
        .tvOS(.v15),
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
		)
    ]
)
