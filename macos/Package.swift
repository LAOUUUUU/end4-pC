// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EndLyrics",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "EndLyrics", targets: ["EndLyrics"]),
    ],
    targets: [
        .target(name: "LyricsCore"),
        .target(name: "SpotifyKit"),
        .executableTarget(
            name: "EndLyrics",
            dependencies: ["LyricsCore", "SpotifyKit"]
        ),
        .testTarget(name: "LyricsCoreTests", dependencies: ["LyricsCore"]),
        .testTarget(name: "SpotifyKitTests", dependencies: ["SpotifyKit"]),
    ],
    swiftLanguageModes: [.v5]
)
