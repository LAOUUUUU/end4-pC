import Foundation
import Appearance
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
    /// Title and artist of the current track, for file names and the LRC header.
    @Published private(set) var trackTitle: String?
    @Published private(set) var trackArtist: String?
    /// The lyric lines currently loaded, for export.
    var loadedLines: [LyricLine] { lines }

    /// Cover art URL of the current track. Shown only in the Now Playing view, with attribution.
    @Published private(set) var artworkURL: URL?
    /// Link to the current track on Spotify, for the attribution link.
    @Published private(set) var spotifyTrackURL: URL?
    /// Seconds added to the playback position when choosing the lyric line (from settings).
    var offsetSeconds = 0.0
    /// Playback state from Spotify, shown on the shuffle and repeat buttons.
    @Published private(set) var shuffling = false
    @Published private(set) var repeating = false
    /// 0...1 through the current track, updated while it plays.
    @Published private(set) var progress = 0.0
    /// Spotify's output volume, 0...100.
    @Published var volume: Double = 0
    /// Now Playing view (cover, large lyrics) instead of the standard panel.
    @Published var expanded = false
    private var trackDuration = 0.0
    /// Seconds of the current track, from the last poll.
    var durationSeconds: Double { trackDuration }
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
            shuffling = snapshot.shuffling
            repeating = snapshot.repeating
            if !volumeEditing { volume = Double(snapshot.volume) }
            trackDuration = snapshot.duration
            clock.resync(position: snapshot.position, playing: snapshot.state == .playing, at: Date())
            let afterError = status.isError
            if TrackChangePolicy.shouldLoad(previous: trackID, next: snapshot.trackID, afterError: afterError) {
                trackID = snapshot.trackID
                artworkURL = snapshot.artworkURL
                trackTitle = snapshot.title
                trackArtist = snapshot.artist
                let id = snapshot.trackID.split(separator: ":").last.map(String.init) ?? ""
                spotifyTrackURL = id.isEmpty ? nil : URL(string: "https://open.spotify.com/track/\(id)")
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
        let position = clock.position(at: Date()) + Self.leadSeconds + offsetSeconds
        let index = LyricsTimeline.activeIndex(at: position, in: lines)
        if index != activeIndex { setActive(index) }
        let fraction = PlaybackProgress.fraction(position: clock.position(at: Date()), duration: trackDuration)
        if abs(fraction - progress) > 0.002 { progress = fraction }
        let word = WordTiming.activeWordIndex(in: activeWords, at: position)
        if word != highlightedWord { highlightedWord = word }
    }

    /// True while the user drags the volume slider, so polls do not fight the drag.
    var volumeEditing = false

    func setVolume(_ level: Double) {
        volume = level
        let value = Int(level.rounded())
        Task { await SpotifyVolume.send(value) }
    }

    /// Jumps to `fraction` (0...1) of the current track. Used by the seek bar.
    func seek(toFraction fraction: Double) {
        guard trackDuration > 0 else { return }
        let time = min(1, max(0, fraction)) * trackDuration
        clock.resync(position: time, playing: isPlaying, at: Date())
        progress = min(1, max(0, fraction))
        Task { await SpotifySeek.send(to: time) }
    }

    func togglePlayPause() {
        isPlaying.toggle()
        Task { await SpotifyCommand.playPause.send() }
    }

    func toggleShuffle() {
        shuffling.toggle()
        let on = shuffling
        Task { await SpotifyToggle.send(SpotifyToggle.shuffle(on: on)) }
    }

    func toggleRepeat() {
        repeating.toggle()
        let on = repeating
        Task { await SpotifyToggle.send(SpotifyToggle.repeating(on: on)) }
    }

    /// Jumps Spotify to the start of the lyric line shown in `slot` (0...6).
    func seek(toSlot slot: Int) {
        let index = activeIndex - LyricsTimeline.before + slot
        guard index >= 0, index < lines.count else { return }
        let time = lines[index].time
        clock.resync(position: time, playing: isPlaying, at: Date())
        Task { await SpotifySeek.send(to: time) }
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
