package name.gaspardruan.nuitcomic.reader

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PageInfoTest {
    @Test fun exifRotationChangesLayoutDimensionsBeforeDecodingPixels() {
        for (orientation in 1..8) {
            val page = PageInfo(File("unused"), 4000, 3000, orientation)
            assertEquals(if (orientation >= 5) 3000 else 4000, page.width)
            assertEquals(if (orientation >= 5) 4000 else 3000, page.height)
        }
    }

    @Test fun tilesCoverTheEntireImageWithoutGapsOrOverlap() {
        for (orientation in 1..8) {
            for (displayWidth in listOf(320, 1080, 2160)) {
                val page = PageInfo(File("unused"), 3000, 42001, orientation)
                val heights = (0 until page.tileCount(displayWidth)).map { page.tileHeight(it, displayWidth) }
                assertTrue(heights.isNotEmpty())
                assertTrue(heights.all { it > 0 && it <= page.tileSourceHeight(displayWidth) })
                assertEquals(page.height, heights.sum())
                assertTrue(heights.dropLast(1).all { it == page.tileSourceHeight(displayWidth) })
            }
        }
    }

    @Test fun theLastTileKeepsItsActualHeight() {
        val page = PageInfo(File("unused"), 1000, 4000, 1)
        assertEquals(3, page.tileCount(1000))
        assertEquals(listOf(1536, 1536, 928), (0..2).map { page.tileHeight(it, 1000) })
    }

    @Test fun aSmallPageUsesOneTileAtItsNaturalAspectRatio() {
        val page = PageInfo(File("unused"), 400, 600, 1)
        assertEquals(1, page.tileCount(400))
        assertEquals(600, page.tileHeight(0, 400))
    }
}
