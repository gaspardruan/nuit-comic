//
//  Cache.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/23.
//

import Cache
import Foundation

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
