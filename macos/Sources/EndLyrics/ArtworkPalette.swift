import Appearance
import CoreGraphics
import Foundation
import ImageIO

/// Downloads a track's cover art, shrinks it to 32×32 and returns its dominant colours.
/// The image itself is never shown, only the colours taken from it.
enum ArtworkPalette {
    private static let sampleSize = 32

    static func colors(from url: URL) async -> [RGB] {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceThumbnailMaxPixelSize: sampleSize,
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
              ] as CFDictionary)
        else { return [] }

        return DominantColors.pick(from: pixels(of: thumbnail), count: 3)
    }

    private static func pixels(of image: CGImage) -> [RGB] {
        let width = image.width
        let height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return stride(from: 0, to: bytes.count, by: 4).map { i in
            RGB(red: Double(bytes[i]) / 255, green: Double(bytes[i + 1]) / 255, blue: Double(bytes[i + 2]) / 255)
        }
    }
}
