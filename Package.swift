// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TarotMystica",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TarotMystica", targets: ["TarotMystica"]),
    ],
    targets: [
        .target(
            name: "TarotMystica",
            path: "TarotMystica",
            resources: [
                .copy("Resources"),
            ]
        ),
    ]
)
