// swift-tools-version: 5.7

import PackageDescription


let package = Package(
    name: "darwin-restclient",
	platforms: [
		.iOS(.v14),
		.watchOS(.v7),
		.macOS(.v11)
	],
    products: [
        .library(
            name: "RestClient",
            targets: ["RestClient"]
		),
    ],
    targets: [
        .target(
            name: "RestClient",
            dependencies: [],
			path: "Sources"
		)
    ]
)
