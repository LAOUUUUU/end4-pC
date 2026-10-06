import AudioVisualizer
import CoreAudio
import Foundation

public enum SpotifyAudioTapError: Error, Equatable {
    /// A Core Audio call failed. `operation` names the call.
    case status(OSStatus, operation: String)
    /// Spotify is not currently producing audio, so there is nothing to tap.
    case noSpotifyAudioProcess
}

/// Taps the audio that Spotify is producing, through a Core Audio process tap (macOS 14.2+).
/// The tap is unmuted, so Spotify keeps playing normally. It needs the system-audio
/// permission (`NSAudioCaptureUsageDescription`), not Screen Recording.
@available(macOS 14.2, *)
public final class SpotifyAudioTap {
    /// Receives mono samples, on a background queue.
    public typealias Handler = @Sendable ([Float]) -> Void

    private var tapID = AudioObjectID(kAudioObjectUnknown)
    private var aggregateID = AudioObjectID(kAudioObjectUnknown)
    private var ioProcID: AudioDeviceIOProcID?
    private let queue = DispatchQueue(label: "io.github.endlyrics.audio-tap")

    /// Sample rate of the tapped audio, known once `start` has succeeded.
    public private(set) var sampleRate: Double = 48_000

    public init() {}

    /// Starts tapping every process whose bundle id starts with `bundlePrefix` that is producing audio.
    public func start(bundlePrefix: String = "com.spotify", handler: @escaping Handler) throws {
        stop()

        let processes = try Self.outputProcesses(bundlePrefix: bundlePrefix)
        guard !processes.isEmpty else { throw SpotifyAudioTapError.noSpotifyAudioProcess }

        let description = CATapDescription(stereoMixdownOfProcesses: processes)
        description.uuid = UUID()
        description.muteBehavior = .unmuted
        description.isPrivate = true
        try Self.check(AudioHardwareCreateProcessTap(description, &tapID), "create process tap")
        sampleRate = try Self.tapSampleRate(tapID)

        let aggregate: [String: Any] = [
            kAudioAggregateDeviceNameKey: "EndLyrics Tap",
            kAudioAggregateDeviceUIDKey: UUID().uuidString,
            kAudioAggregateDeviceIsPrivateKey: 1,
            kAudioAggregateDeviceTapAutoStartKey: 1,
            kAudioAggregateDeviceTapListKey: [[
                kAudioSubTapUIDKey: description.uuid.uuidString,
                kAudioSubTapDriftCompensationKey: 1,
            ]],
        ]
        try Self.check(
            AudioHardwareCreateAggregateDevice(aggregate as CFDictionary, &aggregateID),
            "create aggregate device"
        )

        try Self.check(
            AudioDeviceCreateIOProcIDWithBlock(&ioProcID, aggregateID, queue) { _, input, _, _, _ in
                handler(Self.mono(from: input))
            },
            "create IO proc"
        )
        try Self.check(AudioDeviceStart(aggregateID, ioProcID), "start device")
    }

    public func stop() {
        if aggregateID != kAudioObjectUnknown {
            if let ioProcID {
                AudioDeviceStop(aggregateID, ioProcID)
                AudioDeviceDestroyIOProcID(aggregateID, ioProcID)
            }
            AudioHardwareDestroyAggregateDevice(aggregateID)
        }
        if tapID != kAudioObjectUnknown {
            AudioHardwareDestroyProcessTap(tapID)
        }
        aggregateID = AudioObjectID(kAudioObjectUnknown)
        tapID = AudioObjectID(kAudioObjectUnknown)
        ioProcID = nil
    }

    deinit {
        stop()
    }

    /// Audio process objects whose bundle id starts with `bundlePrefix` and that are producing output.
    static func outputProcesses(bundlePrefix: String) throws -> [AudioObjectID] {
        let all = try audioObjectIDs(
            of: AudioObjectID(kAudioObjectSystemObject),
            selector: kAudioHardwarePropertyProcessObjectList
        )
        return all.filter { process in
            let bundle = (try? stringProperty(of: process, selector: kAudioProcessPropertyBundleID)) ?? ""
            let running = (try? uint32Property(of: process, selector: kAudioProcessPropertyIsRunningOutput)) ?? 0
            return bundle.hasPrefix(bundlePrefix) && running != 0
        }
    }

    /// Mono samples from one IO cycle. Interleaved input is one buffer; planar input is one buffer per channel.
    private static func mono(from input: UnsafePointer<AudioBufferList>) -> [Float] {
        let buffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
        let channelBuffers: [[Float]] = buffers.compactMap { buffer in
            guard let data = buffer.mData else { return nil }
            let count = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
            let samples = Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: Float.self), count: count))
            return samples
        }
        guard let first = buffers.first else { return [] }

        if channelBuffers.count == 1 {
            return MonoMixdown.mix(channelBuffers[0], channels: Int(max(1, first.mNumberChannels)))
        }
        // Planar: average the channels frame by frame.
        let frames = channelBuffers.map(\.count).min() ?? 0
        let scale = 1 / Float(channelBuffers.count)
        return (0..<frames).map { frame in
            channelBuffers.reduce(Float(0)) { $0 + $1[frame] } * scale
        }
    }

    private static func tapSampleRate(_ tap: AudioObjectID) throws -> Double {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioTapPropertyFormat,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var format = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        try check(AudioObjectGetPropertyData(tap, &address, 0, nil, &size, &format), "read tap format")
        return format.mSampleRate
    }

    private static func check(_ status: OSStatus, _ operation: String) throws {
        guard status == noErr else { throw SpotifyAudioTapError.status(status, operation: operation) }
    }

    private static func audioObjectIDs(of object: AudioObjectID, selector: AudioObjectPropertySelector) throws -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        try check(AudioObjectGetPropertyDataSize(object, &address, 0, nil, &size), "read property size")
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        try check(AudioObjectGetPropertyData(object, &address, 0, nil, &size, &ids), "read property")
        return ids
    }

    private static func uint32Property(of object: AudioObjectID, selector: AudioObjectPropertySelector) throws -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        try check(AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value), "read uint32 property")
        return value
    }

    private static func stringProperty(of object: AudioObjectID, selector: AudioObjectPropertySelector) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        // Core Audio returns the string retained, so take ownership through Unmanaged.
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        try check(AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value), "read string property")
        guard let cfString = value?.takeRetainedValue() else { return "" }
        return cfString as String
    }
}
