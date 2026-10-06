import Foundation

/// Playback buttons. Each runs one AppleScript command, and only when Spotify is already running.
public enum SpotifyCommand: CaseIterable, Sendable {
    case playPause
    case next
    case previous

    public var script: String {
        let command: String
        switch self {
        case .playPause: command = "playpause"
        case .next: command = "next track"
        case .previous: command = "previous track"
        }
        // The `is running` guard keeps a button press from launching Spotify.
        return """
        if application "Spotify" is running then tell application "Spotify" to \(command)
        """
    }

    /// Sends the command. Failures are ignored: the next poll shows the real state.
    public func send() async {
        _ = await SpotifyBridge.run(script: script)
    }
}
