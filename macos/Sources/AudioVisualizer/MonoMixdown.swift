import Foundation

/// Averages interleaved multi-channel samples into one mono channel.
public enum MonoMixdown {
    /// `samples` is interleaved (L, R, L, R, ...). A trailing partial frame is dropped.
    public static func mix(_ samples: [Float], channels: Int) -> [Float] {
        guard channels > 0 else { return [] }
        let frames = samples.count / channels
        let scale = 1 / Float(channels)
        return (0..<frames).map { frame in
            var sum: Float = 0
            for channel in 0..<channels {
                sum += samples[frame * channels + channel]
            }
            return sum * scale
        }
    }
}
