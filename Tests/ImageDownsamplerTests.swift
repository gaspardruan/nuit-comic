import Foundation
import ImageIO
import UniformTypeIdentifiers

@main
struct ImageDownsamplerTests {
    static func main() {
        autoreleasepool {
            let data = jpeg(width: 6000, height: 4000)
            let source = CGImageSourceCreateWithData(data as CFData, nil)!
            let original = CGImageSourceCreateImageAtIndex(
                source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)!
            let image = ImageDownsampler.downsample(data, pixelWidth: 1200)!
            precondition(image.width == 1200 && image.height == 800)
            let originalBytes = original.bytesPerRow * original.height
            let resizedBytes = image.bytesPerRow * image.height
            precondition(resizedBytes < originalBytes / 20)
            print(
                String(
                    format:
                        "PASS: 6000x4000 photo -> 1200x800; bitmap storage %.1f MiB -> %.1f MiB",
                    Double(originalBytes) / 1_048_576, Double(resizedBytes) / 1_048_576))
        }
        autoreleasepool {
            let image = ImageDownsampler.downsample(
                jpeg(width: 6000, height: 4000, orientation: 6), pixelWidth: 1200)!
            precondition(image.width == 1200 && image.height == 1800)
            print("PASS: EXIF-rotated photos use the displayed width and retain their orientation")
        }
        autoreleasepool {
            let image = ImageDownsampler.downsample(
                jpeg(width: 1200, height: 10000), pixelWidth: 1200)!
            precondition(image.width == 1200 && image.height == 10000)
            print("PASS: a narrow comic strip retains its full width and height")
        }
        autoreleasepool {
            let image = ImageDownsampler.downsample(
                jpeg(width: 600, height: 800), pixelWidth: 1200)!
            precondition(image.width == 600 && image.height == 800)
            print("PASS: smaller images are not upscaled")
        }
        precondition(ImageDownsampler.downsample(Data([0, 1, 2]), pixelWidth: 1200) == nil)
        print("PASS: invalid image data fails without a full-resolution fallback")
    }

    static func jpeg(width: Int, height: Int, orientation: Int = 1) -> Data {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data, UTType.jpeg.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(
            destination, context.makeImage()!,
            [
                kCGImagePropertyOrientation: orientation,
                kCGImageDestinationLossyCompressionQuality: 0.9,
            ] as CFDictionary)
        precondition(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
