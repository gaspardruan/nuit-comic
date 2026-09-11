package name.gaspardruan.nuitcomic.reader

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReaderPrefetchPlannerTest {
    private val width = 400
    private val longPage = PageInfo(File("long-page"), 400, 40_000, 1)
    private val pages = listOf(ReaderPage(0, 0, "long"))
    private val visible = listOf(piece(0, 5), piece(0, 6))

    @Test fun aBudgetSmallerThanOneNearbyStripSkipsBackgroundDecoding() {
        val stripBytes = longPage.tileMemoryBytes(7, width)
        for (budget in listOf(0L, stripBytes - 1)) {
            val planned = nearbyReaderTiles(pages, mapOf("long" to longPage), visible,
                width, viewportHeight = 1800, horizontal = false, byteBudget = budget)
            assertTrue(planned.isEmpty())
        }
    }

    @Test fun constrainedBudgetWarmsNearestOffscreenStripsWithoutIncludingVisibleTiles() {
        val stripBytes = longPage.tileMemoryBytes(7, width)
        val budget = stripBytes * 2 + stripBytes / 2
        val planned = nearbyReaderTiles(pages, mapOf("long" to longPage), visible,
            width, viewportHeight = 1800, horizontal = false, byteBudget = budget)

        assertEquals(setOf(4, 7), planned.map { it.tile }.toSet())
        assertTrue(planned.none { it in visible })
        assertTrue(planned.sumOf { longPage.tileMemoryBytes(it.tile, width) } <= budget)
        assertFalse(planned.any { it.tile == longPage.tileCount(width) - 1 })
    }

    @Test fun horizontalReadingPrioritizesTheWholeNextViewportEvenMidwayThroughALongPage() {
        val followingPage = ReaderPage(0, 1, "following")
        val followingInfo = PageInfo(File("following-page"), 400, 4000, 1)
        val metadata = mapOf("long" to longPage, "following" to followingInfo)
        val budget = followingInfo.tileMemoryBytes(0, width) + followingInfo.tileMemoryBytes(1, width)
        val planned = nearbyReaderTiles(pages + followingPage, metadata, visible,
            width, viewportHeight = 1800, horizontal = true, byteBudget = budget)

        assertEquals("Both strips in the next viewport must be ready before a sideways swipe",
            setOf(1 to 0, 1 to 1), planned.map { it.page to it.tile }.toSet())
        assertTrue(planned.none { it in visible })
        assertTrue(planned.sumOf { metadata.getValue((pages + followingPage)[it.page].url)
            .tileMemoryBytes(it.tile, width) } <= budget)
    }

    private fun piece(page: Int, tile: Int) = PagePiece(page, tile, "${pages[page].key}:$tile")
}
