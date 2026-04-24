//
//  ReaderView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import SwiftUI

struct ReaderView: View {
    let context: ReadingContext

    var body: some View {
        ComicReader(
            comic: context.comic,
            chapters: context.chapters,
            startChapterIndex: context.startChapterIndex,
            onClose: context.onClose
        )
        .interactiveDismissDisabled()
        .modifier(ReaderTransitionModifier(transition: context.transition))
    }
}

private struct ReaderTransitionModifier: ViewModifier {
    let transition: ReaderTransition?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let transition {
            content.navigationTransition(
                .zoom(sourceID: transition.sourceID, in: transition.namespace)
            )
        } else {
            content
        }
    }
}

#Preview {
    ReaderView(
        context: ReadingContext(
            comic: LocalData.comics[0],
            chapters: LocalData.chapters,
            startChapterIndex: 0,
            transition: nil
        ) { _ in }
    )
}
