package name.gaspardruan.nuitcomic.ui

import android.content.Context
import android.graphics.Bitmap
import androidx.activity.ComponentActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.dp
import androidx.test.core.app.ApplicationProvider
import java.io.File
import kotlin.math.abs
import kotlin.math.ceil
import name.gaspardruan.nuitcomic.data.Comic
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class ComicCoverTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()

    @Test fun portraitCoverFitsStableBoundsWithItsOwnRoundedCorners() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val background = Color(0xFF17232B)
        val portrait = Color(0xFF2AD4C6)
        val file = File.createTempFile("portrait-cover-", ".png", context.cacheDir)
        val bitmap = Bitmap.createBitmap(100, 200, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(portrait.toArgb())
        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
        val coverPath = mutableStateOf("")
        try {
            compose.setContent {
                NuitComicTheme {
                    Box(Modifier.fillMaxSize().background(background), contentAlignment = Alignment.Center) {
                        ComicCover(
                            comic = Comic(91, "Portrait fixture", cover = coverPath.value),
                            modifier = Modifier.size(300.dp, 160.dp).testTag("detail-cover"),
                            preferCover = true,
                        )
                    }
                }
            }
            val cover = compose.onNodeWithTag("detail-cover")
            val reservedBounds = cover.fetchSemanticsNode().boundsInRoot
            compose.runOnIdle { coverPath.value = file.toURI().toString() }
            compose.waitUntil(5_000) {
                val image = cover.captureToImage()
                colorsMatch(portrait, image.toPixelMap()[image.width / 2, image.height / 2])
            }
            assertEquals(reservedBounds, cover.fetchSemanticsNode().boundsInRoot)
            val screenshot = cover.captureToImage()
            File(context.cacheDir, "detail-cover-portrait.png").outputStream().use {
                assertTrue(screenshot.asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, it))
            }
            val pixels = screenshot.toPixelMap()
            val middle = pixels.height / 2
            val imageColumns = (0 until pixels.width).filter { colorsMatch(portrait, pixels[it, middle]) }
            val expectedImageWidth = pixels.height / 2
            assertEquals("Portrait must retain its 1:2 ratio", expectedImageWidth.toFloat(), imageColumns.size.toFloat(), 2f)
            val left = imageColumns.first()
            val right = imageColumns.last()
            assertEquals("Portrait must be centered", left.toFloat(), (pixels.width - 1 - right).toFloat(), 2f)
            assertColor(background, pixels[left / 2, middle], "Left letterbox")
            assertColor(background, pixels[(right + pixels.width) / 2, middle], "Right letterbox")
            assertColor(portrait, pixels[pixels.width / 2, 1], "Image top edge")
            assertColor(portrait, pixels[pixels.width / 2, pixels.height - 2], "Image bottom edge")
            val radius = with(compose.density) { 6.dp.toPx() }
            // Stay clear of the antialiased arc, including when the radius is only six pixels.
            val outsideInset = (radius * 0.05f).toInt()
            val insideInset = ceil(radius / 2f).toInt()
            for (rightCorner in listOf(false, true)) {
                for (bottomCorner in listOf(false, true)) {
                    val outsideX = if (rightCorner) right - outsideInset else left + outsideInset
                    val outsideY = if (bottomCorner) pixels.height - 1 - outsideInset else outsideInset
                    val insideX = if (rightCorner) right - insideInset else left + insideInset
                    val insideY = if (bottomCorner) pixels.height - 1 - insideInset else insideInset
                    val location = "${pixels.width}x${pixels.height}, radius=$radius"
                    assertColor(background, pixels[outsideX, outsideY], "Outside rounded corner ($outsideX, $outsideY), $location")
                    assertColor(portrait, pixels[insideX, insideY], "Inside rounded corner ($insideX, $insideY), $location")
                }
            }
        } finally {
            file.delete()
        }
    }

    private fun assertColor(expected: Color, actual: Color, label: String) {
        assertTrue("$label: expected $expected, got $actual", colorsMatch(expected, actual))
    }

    private fun colorsMatch(expected: Color, actual: Color): Boolean =
        abs(expected.red - actual.red) < 0.01f && abs(expected.green - actual.green) < 0.01f &&
            abs(expected.blue - actual.blue) < 0.01f && abs(expected.alpha - actual.alpha) < 0.01f
}
