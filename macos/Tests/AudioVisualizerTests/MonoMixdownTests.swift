import XCTest
@testable import AudioVisualizer

final class MonoMixdownTests: XCTestCase {
    func testMonoInputIsReturnedUnchanged() {
        XCTAssertEqual(MonoMixdown.mix([0.1, -0.2, 0.3], channels: 1), [0.1, -0.2, 0.3])
    }

    func testStereoInterleavedIsAveragedPerFrame() {
        // Frames: (L=1, R=0) and (L=0.5, R=0.5)
        let mono = MonoMixdown.mix([1, 0, 0.5, 0.5], channels: 2)

        XCTAssertEqual(mono.count, 2)
        XCTAssertEqual(mono[0], 0.5, accuracy: 0.0001)
        XCTAssertEqual(mono[1], 0.5, accuracy: 0.0001)
    }

    func testDropsIncompleteTrailingFrame() {
        // Three samples in stereo is one whole frame plus half a frame.
        XCTAssertEqual(MonoMixdown.mix([1, 1, 1], channels: 2).count, 1)
    }

    func testEmptyInputGivesEmptyOutput() {
        XCTAssertEqual(MonoMixdown.mix([], channels: 2), [])
    }
}
