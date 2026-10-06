import Foundation

/// Sets Spotify's output volume (0...100). Only runs when Spotify is already running.
public enum SpotifyVolume {
    public static func script(to level: Int) -> String {
        let clamped = min(100, max(0, level))
        return """
        if application "Spotify" is running then tell application "Spotify" to set sound volume to \(clamped)
        """
    }

    public static func send(_ level: Int) async {
        _ = await SpotifyBridge.run(script: script(to: level))
    }
}
