//
//  ComicListItem.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/24.
//

import SwiftUI

struct ComicListItem: View {
    let comic: Comic
    let highlightQuery: String?

    init(comic: Comic, highlightQuery: String? = nil) {
        self.comic = comic
        self.highlightQuery = highlightQuery
    }

    var body: some View {
        HStack {
            ComicImage(url: comic.image)
                .aspectRatio(5 / 7, contentMode: .fit)
                .cornerRadius(4)
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                highlightedText(comic.title)
                    .font(.subheadline)
                highlightedText(comic.keyword)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                highlightedText(comic.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

        }
        .frame(maxHeight: 126)
    }

    private func highlightedText(_ text: String, defaultColor: Color = .primary) -> Text {
        let trimmedQuery = highlightQuery?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedQuery, !trimmedQuery.isEmpty else {
            return Text(text).foregroundStyle(defaultColor)
        }

        var result = Text("")
        var searchStart = text.startIndex

        while searchStart < text.endIndex,
            let range = text.range(
                of: trimmedQuery,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchStart..<text.endIndex,
                locale: .current)
        {
            if searchStart < range.lowerBound {
                result =
                    result
                    + Text(String(text[searchStart..<range.lowerBound]))
                    .foregroundStyle(defaultColor)
            }
            result =
                result
                + Text(String(text[range]))
                .foregroundStyle(Color.accentColor)
                .bold()

            searchStart = range.upperBound
        }

        if searchStart < text.endIndex {
            result =
                result
                + Text(String(text[searchStart..<text.endIndex]))
                .foregroundStyle(defaultColor)
        }

        return result
    }
}

#Preview {
    ComicListItem(comic: LocalData.comics[0])
        .border(.black)
}

#Preview("highlight") {
    ComicListItem(comic: LocalData.comics[0], highlightQuery: "偷")
}
