//
//  KingfisherSetup.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
//

import Alamofire
import Cache
import Foundation
import Kingfisher

enum ServerConfig {

    static let referer = "https://yymh.app/"

    static let apiBaseUrl = "https://yymh.app/home/api"

    static let imageBaseUrl = "https://icnyy.tengxun.best/public"

    static let pageSize = 20

    // Kingfisher Request Modifier
    static let requestModifier = AnyModifier { request in
        var r = request
        r.setValue(referer, forHTTPHeaderField: "Referer")
        return r
    }
}

let jsonStorage: Storage<String, Data> = {
    let diskConfig = DiskConfig(
        name: "json_cache"
    )

    let memoryConfig = MemoryConfig(
        expiry: .seconds(180),
        countLimit: 100
    )

    return try! Storage(
        diskConfig: diskConfig,
        memoryConfig: memoryConfig,
        fileManager: .default,
        transformer: TransformerFactory.forData()
    )
}()

func setupKingfisher() {
    let cache = ImageCache.default

    cache.memoryStorage.config.totalCostLimit = 800 * 1024 * 1024  // 800MB
    cache.memoryStorage.config.expiration = .seconds(60)

    cache.diskStorage.config.sizeLimit = 2 * 1024 * 1024 * 1024  // 2GB
    cache.diskStorage.config.expiration = .seconds(60 * 5)

    ImageDownloader.default.downloadTimeout = 15
    ImageDownloader.default.sessionConfiguration.httpMaximumConnectionsPerHost = 9
}
