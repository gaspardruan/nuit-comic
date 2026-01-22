//
//  KingfisherSetup.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import Kingfisher

enum ServerConfig {

    // 漫画站点 Referer
    static let referer = "https://yymh.app/"

    static let apiBaseUrl = "https://yymh.app/home/api"

    static let imageBaseUrl = "https://icny.tengxun.click/public"

    // Kingfisher Request Modifier
    static let requestModifier = AnyModifier { request in
        var r = request
        r.setValue(referer, forHTTPHeaderField: "Referer")
        return r
    }
}

func setupKingfisher() {
    let cache = ImageCache.default

    // 内存缓存（漫画建议大）
    cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024  // 300MB
    cache.memoryStorage.config.expiration = .seconds(60 * 60)

    // 磁盘缓存
    cache.diskStorage.config.sizeLimit = 2 * 1024 * 1024 * 1024  // 2GB
    cache.diskStorage.config.expiration = .days(7)

    // 下载配置
    ImageDownloader.default.downloadTimeout = 15
    ImageDownloader.default.sessionConfiguration.httpMaximumConnectionsPerHost =
        4
}
