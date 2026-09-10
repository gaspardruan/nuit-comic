import Kingfisher
import UIKit

struct ReaderImageProcessor: ImageProcessor {
    let pixelWidth: Int
    var identifier: String { "nuitcomic.reader.width.\(pixelWidth).v1" }

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> UIImage? {
        switch item {
        case .data(let data):
            guard let image = ImageDownsampler.downsample(data, pixelWidth: pixelWidth) else {
                return nil
            }
            return UIImage(cgImage: image, scale: options.scaleFactor, orientation: .up)
        case .image(let image):
            let scale = min(1, CGFloat(pixelWidth) / (image.size.width * image.scale))
            guard scale < 1 else { return image }
            return image.kf.resize(
                to: CGSize(
                    width: image.size.width * scale, height: image.size.height * scale))
        }
    }
}

enum ReaderImageLoading {
    // Keep processed pages separate from the old full-resolution image cache.
    static let cache: ImageCache = {
        let cache = ImageCache(name: "reader_images_v1")
        cache.memoryStorage.config.totalCostLimit = 192 * 1024 * 1024
        cache.memoryStorage.config.countLimit = 40
        cache.diskStorage.config.sizeLimit = 2 * 1024 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)
        return cache
    }()
}

@MainActor
final class ReaderImagePrefetcher {
    private final class Request {
        var task: DownloadTask?
    }

    private var pixelWidth = 0
    private var desiredURLs: [URL] = []
    private var pendingURLs: [URL] = []
    private var active: [URL: Request] = [:]

    func update(urls: [String], pixelWidth: Int) {
        var seen: Set<URL> = []
        let urls = urls.compactMap(URL.init(string:)).filter { seen.insert($0).inserted }
        guard self.pixelWidth != pixelWidth || desiredURLs != urls else { return }
        if self.pixelWidth != pixelWidth {
            stop()
            self.pixelWidth = pixelWidth
        }

        desiredURLs = urls
        for url in Array(active.keys) where !urls.contains(url) {
            active.removeValue(forKey: url)?.task?.cancel()
        }
        pendingURLs = urls.filter { active[$0] == nil }
        startNextRequests()
    }

    func stop() {
        let requests = Array(active.values)
        active.removeAll()
        pendingURLs.removeAll()
        desiredURLs.removeAll()
        requests.forEach { $0.task?.cancel() }
    }

    private func startNextRequests() {
        while active.count < 2, !pendingURLs.isEmpty {
            let url = pendingURLs.removeFirst()
            let request = Request()
            active[url] = request
            request.task = KingfisherManager.shared.retrieveImage(
                with: url,
                options: [
                    .processor(ReaderImageProcessor(pixelWidth: pixelWidth)),
                    .targetCache(ReaderImageLoading.cache),
                    .originalCache(ReaderImageLoading.cache),
                    .requestModifier(ServerConfig.requestModifier),
                    .backgroundDecode,
                    .downloadPriority(0.2),
                ]
            ) { [weak self, weak request] _ in
                Task { @MainActor in
                    guard let self, let request, self.active[url] === request else { return }
                    self.active.removeValue(forKey: url)
                    self.startNextRequests()
                }
            }
        }
    }
}
