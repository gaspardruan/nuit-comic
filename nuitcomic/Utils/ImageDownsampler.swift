import Foundation
import ImageIO

enum ImageDownsampler {
    static func downsample(_ data: Data, pixelWidth: Int) -> CGImage? {
        guard pixelWidth > 0,
            let source = CGImageSourceCreateWithData(
                data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
            let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
            width.doubleValue > 0, height.doubleValue > 0
        else { return nil }

        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        let displayWidth = (5...8).contains(orientation) ? height.doubleValue : width.doubleValue
        let scale = min(1, Double(pixelWidth) / displayWidth)
        let longestSide = ceil(max(width.doubleValue, height.doubleValue) * scale)

        // Decode directly at display resolution, preserving the full height of long comic strips.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: longestSide,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
