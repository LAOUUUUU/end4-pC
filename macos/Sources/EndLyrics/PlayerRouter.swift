import AppleMusicKit
import Appearance
import Foundation
import SpotifyKit

/// The app a playback read came from. Controls are sent to the same app.
enum MusicSource: Equatable {
    case spotify
    case music

    /// Bundle id prefix used to find the app's audio process for the visualizer.
    var bundlePrefix: String {
        switch self {
        case .spotify: return "com.spotify"
        case .music: return "com.apple.Music"
        }
    }
}

/// Playback commands that exist in both apps.
enum PlayerCommand {
    case playPause
    case next
    case previous
}

/// Reads and controls whichever music app the settings choose.
/// With `automatic`, it prefers a playing Spotify, then a playing Apple Music.
@MainActor
final class PlayerRouter {
    var choice: PlayerChoice = .spotify
    private(set) var source: MusicSource = .spotify

    func read() async -> Result<PlaybackSnapshot?, SpotifyBridgeError> {
        switch choice {
        case .spotify:
            source = .spotify
            return await SpotifyBridge.read()
        case .appleMusic:
            source = .music
            return await readMusic()
        case .automatic:
            let spotify = await SpotifyBridge.read()
            if case .success(let snapshot?) = spotify, snapshot.state == .playing {
                source = .spotify
                return spotify
            }
            let music = await readMusic()
            if case .success(let snapshot?) = music, snapshot.state == .playing {
                source = .music
                return music
            }
            source = .spotify
            return spotify
        }
    }

    func command(_ command: PlayerCommand) async {
        switch source {
        case .spotify:
            switch command {
            case .playPause: await SpotifyCommand.playPause.send()
            case .next: await SpotifyCommand.next.send()
            case .previous: await SpotifyCommand.previous.send()
            }
        case .music:
            let verb: String
            switch command {
            case .playPause: verb = "playpause"
            case .next: verb = "next track"
            case .previous: verb = "previous track"
            }
            _ = await SpotifyBridge.run(script: AppleMusicScript.command(verb))
        }
    }

    func seek(to seconds: Double) async {
        switch source {
        case .spotify: await SpotifySeek.send(to: seconds)
        case .music: _ = await SpotifyBridge.run(script: AppleMusicScript.seek(to: seconds))
        }
    }

    func setVolume(_ level: Int) async {
        switch source {
        case .spotify: await SpotifyVolume.send(level)
        case .music: _ = await SpotifyBridge.run(script: AppleMusicScript.volume(level))
        }
    }

    func setShuffle(_ on: Bool) async {
        switch source {
        case .spotify: await SpotifyToggle.send(SpotifyToggle.shuffle(on: on))
        case .music: _ = await SpotifyBridge.run(script: AppleMusicScript.shuffle(on: on))
        }
    }

    func setRepeat(_ on: Bool) async {
        switch source {
        case .spotify: await SpotifyToggle.send(SpotifyToggle.repeating(on: on))
        case .music: _ = await SpotifyBridge.run(script: AppleMusicScript.repeating(on: on))
        }
    }

    private func readMusic() async -> Result<PlaybackSnapshot?, SpotifyBridgeError> {
        let run = await SpotifyBridge.run(script: AppleMusicScript.readScript)
        guard run.exitCode == 0 else {
            return .failure(.scriptFailed(run.stderr.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        return .success(AppleMusicParser.parse(run.stdout))
    }
}
