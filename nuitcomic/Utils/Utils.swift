//
//  Utils.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
//

import Foundation

func appVersion() -> String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
}

/// Load file from the file system.
///
/// `load` expects a JSON file. Use the method to load the example data.
func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

/// Transform the time string of resonse to Date
/// example: "2022-02-17 19:23:41"
func transTime(from timeString: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.date(from: timeString)!
}

func formatTime(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    return formatter.string(from: date)
}

func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
    lhs.compare(rhs, options: .numeric) == .orderedDescending
}

let dateFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.locale = Locale(identifier: "zh_CN")
    f.unitsStyle = .full
    return f
}()

func generateImageItemList(
    from imageList: [String],
    chapterIndex: Int,
    startIndexInList: Int = 0
) -> [ImageItem] {
    imageList.enumerated().map { index, image in
        ImageItem(
            url: image,
            indexInChapter: index,
            chapterIndex: chapterIndex,
            indexInList: index + startIndexInList
        )
    }
}
