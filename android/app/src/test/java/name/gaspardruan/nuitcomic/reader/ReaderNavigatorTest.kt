package name.gaspardruan.nuitcomic.reader

import name.gaspardruan.nuitcomic.data.Chapter
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ReaderNavigatorTest {
    private val navigator = ReaderNavigator(listOf(
        Chapter(11, "First", listOf("a", "b")),
        Chapter(12, "Empty", emptyList()),
        Chapter(13, "Third", listOf("c", "d", "e")),
        Chapter(14, "Trailing empty", emptyList()),
    ))

    @Test fun chapterJumpsResolveToTheRequestedChapterAndPage() {
        assertEquals(ReaderPage(0, 0, "a"), navigator.pageAt(navigator.position(0)))
        assertEquals(ReaderPage(2, 0, "c"), navigator.pageAt(navigator.position(2)))
        assertEquals(ReaderPage(2, 2, "e"), navigator.pageAt(navigator.position(2, 2)))
    }

    @Test fun savedPageIsClampedWhenChapterContentsChange() {
        assertEquals(ReaderPage(2, 2, "e"), navigator.pageAt(navigator.position(2, Int.MAX_VALUE)))
        assertEquals(ReaderPage(2, 0, "c"), navigator.pageAt(navigator.position(2, -1)))
    }

    @Test fun emptyChapterSelectsTheNextReadableChapter() {
        assertEquals(ReaderPage(2, 0, "c"), navigator.pageAt(navigator.position(1, 100)))
    }

    @Test fun obsoleteChapterOrTrailingEmptyChapterRestartsAtFirstPage() {
        // Match iOS restoration when a stored chapter no longer exists.
        for (chapter in listOf(-1, 3, 4, Int.MAX_VALUE)) {
            assertEquals(ReaderPage(0, 0, "a"), navigator.pageAt(navigator.position(chapter)))
        }
    }

    @Test fun emptyBooksHaveNoReadablePosition() {
        for (chapters in listOf(emptyList(), listOf(Chapter(1, "Empty", emptyList())))) {
            val empty = ReaderNavigator(chapters)
            assertTrue(empty.pages.isEmpty())
            assertNull(empty.pageAt(empty.position(0)))
            assertNull(empty.pageAt(empty.position(999, 999)))
        }
    }

    @Test fun obsoleteVisibleIndicesAreIgnored() {
        assertNull(navigator.pageAt(-1))
        assertNull(navigator.pageAt(navigator.pages.size))
        assertNull(navigator.pageAt(Int.MAX_VALUE))
        assertEquals(5, navigator.pages.size)
    }

    @Test fun repeatedImageUrlsStillHaveDistinctPageIdentities() {
        val repeated = ReaderNavigator(listOf(
            Chapter(1, "One", listOf("same", "same")),
            Chapter(2, "Two", listOf("same")),
        ))
        assertEquals(3, repeated.pages.map { it.key }.toSet().size)
        assertEquals(listOf("0:0", "0:1", "1:0"), repeated.pages.map { it.key })
    }
}
