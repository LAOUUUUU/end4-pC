import Foundation

/// Shuffle and repeat switches. Each script only runs when Spotify is already running.
public enum SpotifyToggle {
    public static func shuffle(on: Bool) -> String {
        guardedScript("set shuffling to \(on)")
    }

    public static func repeating(on: Bool) -> String {
        guardedScript("set repeating to \(on)")
    }

    private static func guardedScript(_ statement: String) -> String {
        """
        if application "Spotify" is running then tell application "Spotify" to \(statement)
        """
    }

    public static func send(_ script: String) async {
        _ = await SpotifyBridge.run(script: script)
    }
}
