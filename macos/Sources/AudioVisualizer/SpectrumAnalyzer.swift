import Foundation

/// Turns a block of audio samples into a row of band levels, each in 0...1.
/// Hann-windowed radix-2 FFT, bands spaced logarithmically from 40 Hz up to 16 kHz
/// (or Nyquist, whichever is lower), levels mapped from -70 dB to 0 dB.
public struct SpectrumAnalyzer: Sendable {
    public let fftSize: Int
    public let bandCount: Int
    public let sampleRate: Double

    private static let lowestFrequency = 40.0
    private static let highestFrequency = 16_000.0
    private static let floorDecibels = -70.0

    private let window: [Float]
    /// `bandCount + 1` edges in Hz, ascending.
    private let edges: [Double]

    public init(fftSize: Int, bandCount: Int, sampleRate: Double) {
        precondition(fftSize > 1 && fftSize & (fftSize - 1) == 0, "fftSize must be a power of two")
        self.fftSize = fftSize
        self.bandCount = bandCount
        self.sampleRate = sampleRate

        window = (0..<fftSize).map { n in
            Float(0.5 - 0.5 * cos(2 * Double.pi * Double(n) / Double(fftSize - 1)))
        }

        let top = min(Self.highestFrequency, sampleRate / 2)
        let ratio = top / Self.lowestFrequency
        edges = (0...bandCount).map { b in
            Self.lowestFrequency * pow(ratio, Double(b) / Double(bandCount))
        }
    }

    /// Band levels for one block of samples. Short blocks are zero-padded.
    public func bands(samples: [Float]) -> [Float] {
        var re = [Float](repeating: 0, count: fftSize)
        var im = [Float](repeating: 0, count: fftSize)
        for i in 0..<min(fftSize, samples.count) {
            re[i] = samples[i] * window[i]
        }
        Self.fft(re: &re, im: &im)

        let half = fftSize / 2
        // Normalized magnitude per bin: 0...1 for a full-scale tone at the bin.
        let magnitudes = (0...half).map { k in
            sqrt(re[k] * re[k] + im[k] * im[k]) / Float(half)
        }

        return (0..<bandCount).map { b in
            let low = edges[b]
            let high = edges[b + 1]
            var sum: Float = 0
            var count = 0
            for k in 0...half {
                let frequency = binFrequency(k)
                if frequency >= low && frequency < high {
                    sum += magnitudes[k]
                    count += 1
                }
            }
            // Low bands can be narrower than one bin. Use the bin nearest the band centre.
            let average = count > 0 ? sum / Float(count) : magnitudes[nearestBin(to: (low * high).squareRoot())]
            return Self.level(for: average)
        }
    }

    /// The band whose edges contain `frequency`, clamped to the valid range.
    public func bandIndex(containing frequency: Double) -> Int {
        guard frequency >= edges[0] else { return 0 }
        for b in 0..<bandCount where frequency < edges[b + 1] {
            return b
        }
        return bandCount - 1
    }

    private func binFrequency(_ bin: Int) -> Double {
        Double(bin) * sampleRate / Double(fftSize)
    }

    private func nearestBin(to frequency: Double) -> Int {
        min(fftSize / 2, max(0, Int((frequency * Double(fftSize) / sampleRate).rounded())))
    }

    private static func level(for magnitude: Float) -> Float {
        let decibels = 20 * log10(max(Double(magnitude), 1e-9))
        let scaled = (decibels - floorDecibels) / -floorDecibels
        return Float(min(1, max(0, scaled)))
    }

    /// In-place iterative radix-2 FFT. `re` and `im` must have the same power-of-two length.
    private static func fft(re: inout [Float], im: inout [Float]) {
        let n = re.count

        var j = 0
        for i in 1..<n {
            var bit = n >> 1
            while j & bit != 0 {
                j ^= bit
                bit >>= 1
            }
            j ^= bit
            if i < j {
                re.swapAt(i, j)
                im.swapAt(i, j)
            }
        }

        var length = 2
        while length <= n {
            let angle = -2 * Double.pi / Double(length)
            let stepRe = Float(cos(angle))
            let stepIm = Float(sin(angle))
            var start = 0
            while start < n {
                var twiddleRe: Float = 1
                var twiddleIm: Float = 0
                for k in 0..<(length / 2) {
                    let a = start + k
                    let b = a + length / 2
                    let tr = re[b] * twiddleRe - im[b] * twiddleIm
                    let ti = re[b] * twiddleIm + im[b] * twiddleRe
                    re[b] = re[a] - tr
                    im[b] = im[a] - ti
                    re[a] += tr
                    im[a] += ti
                    let nextRe = twiddleRe * stepRe - twiddleIm * stepIm
                    twiddleIm = twiddleRe * stepIm + twiddleIm * stepRe
                    twiddleRe = nextRe
                }
                start += length
            }
            length <<= 1
        }
    }
}
