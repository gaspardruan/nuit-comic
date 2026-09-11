package name.gaspardruan.nuitcomic.reader

import name.gaspardruan.nuitcomic.data.Chapter

/** The visible page is the single source of truth for chapter and page labels. */
data class ReaderPage(val chapterIndex: Int, val pageIndex: Int, val url: String) {
    val key: String get() = "$chapterIndex:$pageIndex"
}

class ReaderNavigator(val chapters: List<Chapter>) {
    val pages: List<ReaderPage> = chapters.flatMapIndexed { chapter, item ->
        item.images.mapIndexed { page, url -> ReaderPage(chapter, page, url) }
    }

    fun position(chapter: Int, page: Int = 0): Int {
        val first = pages.indexOfFirst { it.chapterIndex == chapter }
        if (first < 0) return pages.indexOfFirst { it.chapterIndex >= chapter }.coerceAtLeast(0)
        return first + page.coerceIn(0, chapters[chapter].images.lastIndex)
    }

    fun pageAt(index: Int): ReaderPage? = pages.getOrNull(index)
}
