import XCTest
@testable import AudioVisualizer

final class SpectrumAnalyzerTests: XCTestCase {
    private let sampleRate = 44_100.0

    private func sine(frequency: Double, amplitude: Float, count: Int) -> [Float] {
        (0..<count).map { n in
            amplitude * Float(sin(2 * Double.pi * frequency * Double(n) / sampleRate))
        }
    }

    func testSilenceProducesZeroBands() {
        let analyzer = SpectrumAnalyzer(fftSize: 1024, bandCount: 24, sampleRate: sampleRate)

        let bands = analyzer.bands(samples: Array(repeating: 0, count: 1024))

        XCTAssertEqual(bands.count, 24)
        XCTAssertTrue(bands.allSatisfy { $0 == 0 })
    }

    func testToneLandsInTheBandThatContainsItsFrequency() {
        let analyzer = SpectrumAnalyzer(fftSize: 1024, bandCount: 24, sampleRate: sampleRate)

        let bands = analyzer.bands(samples: sine(frequency: 1_000, amplitude: 0.8, count: 1024))
        let peak = bands.indices.max { bands[$0] < bands[$1] }

        XCTAssertEqual(peak, analyzer.bandIndex(containing: 1_000))
    }

    func testBandsStayWithinZeroToOne() {
        let analyzer = SpectrumAnalyzer(fftSize: 1024, bandCount: 24, sampleRate: sampleRate)

        let bands = analyzer.bands(samples: sine(frequency: 220, amplitude: 1.0, count: 1024))

        XCTAssertTrue(bands.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    func testShortInputIsPaddedNotRejected() {
        let analyzer = SpectrumAnalyzer(fftSize: 1024, bandCount: 24, sampleRate: sampleRate)

        let bands = analyzer.bands(samples: sine(frequency: 1_000, amplitude: 0.8, count: 300))

        XCTAssertEqual(bands.count, 24)
    }

    func testBandIndexIsMonotonicInFrequency() {
        let analyzer = SpectrumAnalyzer(fftSize: 1024, bandCount: 24, sampleRate: sampleRate)

        XCTAssertLessThan(analyzer.bandIndex(containing: 100), analyzer.bandIndex(containing: 1_000))
        XCTAssertLessThan(analyzer.bandIndex(containing: 1_000), analyzer.bandIndex(containing: 10_000))
    }
}
