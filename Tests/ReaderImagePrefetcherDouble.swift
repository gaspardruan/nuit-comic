import Foundation

@MainActor
final class ReaderImagePrefetcher {
    struct Update {
        let urls: [String]
        let pixelWidth: Int
    }

    static var instances: [ReaderImagePrefetcher] = []
    private(set) var updates: [Update] = []
    private(set) var stopCount = 0

    init() { Self.instances.append(self) }
    func update(urls: [String], pixelWidth: Int) {
        updates.append(Update(urls: urls, pixelWidth: pixelWidth))
    }
    func stop() { stopCount += 1 }
}
