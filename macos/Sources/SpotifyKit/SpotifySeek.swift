import Foundation

/// Moves Spotify's playback position. Only runs when Spotify is already running.
public enum SpotifySeek {
    public static func script(to seconds: Double) -> String {
        let position = max(0, seconds)
        return """
        if application "Spotify" is running then tell application "Spotify" to set player position to \(position)
        """
    }

    public static func send(to seconds: Double) async {
        _ = await SpotifyBridge.run(script: script(to: seconds))
    }
}
