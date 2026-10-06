import Foundation

/// Decides whether a poll should (re)load lyrics for the track it just read.
public enum TrackChangePolicy {
    /// Load when the track changed, or when the previous read failed, so the window recovers.
    public static func shouldLoad(previous: String?, next: String, afterError: Bool) -> Bool {
        previous != next || afterError
    }
}
