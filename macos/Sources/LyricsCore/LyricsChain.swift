import Foundation

/// A source of synced lyrics. Implementations return `nil` when they have nothing for the track.
public protocol LyricsProvider: Sendable {
    /// Short name shown in logs and tests, for example "LRCLIB".
    var name: String { get }

    func fetch(title: String, artist: String, duration: Double) async -> [LyricLine]?
}

/// Asks providers in order and returns the first non-empty answer, with the provider's name.
public struct LyricsChain: Sendable {
    public struct Result: Equatable, Sendable {
        public let provider: String
        public let lines: [LyricLine]
    }

    private let providers: [any LyricsProvider]

    public init(providers: [any LyricsProvider]) {
        self.providers = providers
    }

    public func lyrics(title: String, artist: String, duration: Double) async -> Result? {
        for provider in providers {
            guard let lines = await provider.fetch(title: title, artist: artist, duration: duration),
                  !lines.isEmpty
            else { continue }
            return Result(provider: provider.name, lines: lines)
        }
        return nil
    }
}

/// LRCLIB as a provider in the chain.
public struct LRCLibProvider: LyricsProvider {
    public let name = "LRCLIB"

    public init() {}

    public func fetch(title: String, artist: String, duration: Double) async -> [LyricLine]? {
        await LRCLibClient.fetchSyncedLyrics(title: title, artist: artist, duration: duration)
    }
}
