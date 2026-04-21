//
//  KingfisherSetup.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import Alamofire
import Cache
import Foundation
import Kingfisher

enum ServerConfig {

    // 漫画站点 Referer
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

// 请求缓存
let jsonStorage: Storage<String, Data> = {
    let diskConfig = DiskConfig(
        name: "json_cache"
    )

    let memoryConfig = MemoryConfig(
        expiry: .seconds(180),  // 3 分钟
        countLimit: 100
    )

    return try! Storage(
        diskConfig: diskConfig,
        memoryConfig: memoryConfig,
        fileManager: .default,
        transformer: TransformerFactory.forData()
    )
}()

// 图片缓存
func setupKingfisher() {
    let cache = ImageCache.default

    // 内存缓存（漫画建议大）
    cache.memoryStorage.config.totalCostLimit = 800 * 1024 * 1024  // 800MB
    cache.memoryStorage.config.expiration = .seconds(60)

    // 磁盘缓存
    cache.diskStorage.config.sizeLimit = 2 * 1024 * 1024 * 1024  // 2GB
    cache.diskStorage.config.expiration = .seconds(60 * 5)

    // 下载配置
    ImageDownloader.default.downloadTimeout = 15
    ImageDownloader.default.sessionConfiguration.httpMaximumConnectionsPerHost =
        9
}
