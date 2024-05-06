// swift-tools-version: 5.7

import PackageDescription


let package = Package(
    name: "darwin-httpclient",
	platforms: [
		.iOS(.v15),
		.watchOS(.v7),
		.macOS(.v11)
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
