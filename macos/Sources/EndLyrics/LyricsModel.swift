import Foundation
import LyricsCore
import SpotifyKit

/// Drives the lyrics window: polls Spotify, loads lyrics for each new track,
/// and advances the active line between polls. Mirrors `services/LyricsService.qml`.
@MainActor
final class LyricsModel: ObservableObject {
    enum Status: Equatable {
        case nothingPlaying
        case loading
        case synced
        case notFound
        case error(String)

        var isError: Bool {
            if case .error = self { return true }
            return false
        }
    }

    /// Seconds to look ahead, so a line lights up just before it is sung (`leadSeconds` in the widget).
    static let leadSeconds = 0.15

    @Published private(set) var status: Status = .nothingPlaying
    /// "Title — Artist" for the track Spotify reported last, or nil when nothing is playing.
    @Published private(set) var nowPlaying: String?
    /// True while Spotify reports the playing state. The visualizer taps audio only then.
    @Published private(set) var isPlaying = false
    @Published private(set) var slots: [String] = Array(repeating: "", count: LyricsTimeline.total)
    @Published private(set) var activeIndex = -1
    /// Estimated word timing for the active line, for the karaoke highlight.
    @Published private(set) var activeWords: [WordSpan] = []
    /// Index into `activeWords` of the word being sung, or -1.
    @Published private(set) var highlightedWord = -1

    /// Sources tried in order. LRCLIB first, then NetEase for tracks LRCLIB lacks.
    private static let chain = LyricsChain(providers: [LRCLibProvider(), NetEaseProvider()])

    private var lines: [LyricLine] = []
    /// Which source supplied the current lyrics, shown in the window.
    @Published private(set) var providerName: String?
    private var clock = PositionClock()
    private var trackID: String?
    private let cache = LyricsCache.standard
    private var loadTask: Task<Void, Never>?
    private var started = false

    func start() {
        guard !started else { return }
        started = true

        Task { [weak self] in
            while !Task.isCancelled {
                await self?.poll()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func poll() async {
        switch await SpotifyBridge.read() {
        case .failure(let error):
            if case .scriptFailed(let message) = error {
                status = .error(message)
            }
        case .success(nil):
            trackID = nil
            loadTask?.cancel()
            lines = []
            setActive(-1)
            nowPlaying = nil
            isPlaying = false
            providerName = nil
            status = .nothingPlaying
        case .success(let snapshot?):
            nowPlaying = "\(snapshot.title) — \(snapshot.artist)"
            isPlaying = snapshot.state == .playing
            clock.resync(position: snapshot.position, playing: snapshot.state == .playing, at: Date())
            let afterError = status.isError
            if TrackChangePolicy.shouldLoad(previous: trackID, next: snapshot.trackID, afterError: afterError) {
                trackID = snapshot.trackID
                startLoading(snapshot)
            }
        }
    }

    private func startLoading(_ snapshot: PlaybackSnapshot) {
        loadTask?.cancel()
        lines = []
        setActive(-1)
        providerName = nil
        status = .loading

        let key = snapshot.trackID
        if let cached = cache.lines(for: key) {
            lines = cached
            providerName = "cache"
            status = .synced
            return
        }

        loadTask = Task { [weak self] in
            let found = await Self.chain.lyrics(
                title: snapshot.title,
                artist: snapshot.artist,
                duration: snapshot.duration
            )
            guard let self, !Task.isCancelled, self.trackID == key else { return }
            if let found {
                self.cache.store(found.lines, for: key)
                self.lines = found.lines
                self.providerName = found.provider
                self.status = .synced
            } else {
                self.status = .notFound
            }
        }
    }

    private func tick() {
        guard status == .synced else { return }
        let position = clock.position(at: Date()) + Self.leadSeconds
        let index = LyricsTimeline.activeIndex(at: position, in: lines)
        if index != activeIndex { setActive(index) }
        let word = WordTiming.activeWordIndex(in: activeWords, at: position)
        if word != highlightedWord { highlightedWord = word }
    }

    private func setActive(_ index: Int) {
        activeIndex = index
        slots = LyricsTimeline.slots(activeIndex: index, in: lines)
        if index >= 0 && index < lines.count {
            activeWords = WordTiming.spans(
                for: lines[index].text,
                start: lines[index].time,
                end: WordTiming.lineEnd(of: index, in: lines)
            )
        } else {
            activeWords = []
        }
        highlightedWord = -1
    }
}
