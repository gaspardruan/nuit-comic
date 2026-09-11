package name.gaspardruan.nuitcomic.reader

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import androidx.activity.ComponentActivity
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToIndex
import androidx.compose.ui.test.performSemanticsAction
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.test.core.app.ApplicationProvider
import java.io.File
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import kotlin.math.ceil
import kotlin.math.roundToInt
import kotlinx.coroutines.runBlocking
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.ReadingSession
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.readerPreferences
import name.gaspardruan.nuitcomic.ui.NuitComicTheme
import okhttp3.Call
import okhttp3.EventListener
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class ReaderPrefetchTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()

    @Test fun movingTheWindowKeepsOverlappingDownloadsAndCancelsOnlyObsoletePages() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        runBlocking { context.readerPreferences.edit { it[booleanPreferencesKey("horizontal")] = false } }
        val started = ConcurrentHashMap<Int, AtomicInteger>()
        val readingBodies = ConcurrentHashMap.newKeySet<Int>()
        val canceled = ConcurrentHashMap.newKeySet<Int>()
        val client = OkHttpClient.Builder().eventListener(object : EventListener() {
            override fun callStart(call: Call) {
                started.computeIfAbsent(page(call)) { AtomicInteger() }.incrementAndGet()
            }
            override fun responseBodyStart(call: Call) { readingBodies.add(page(call)) }
            override fun canceled(call: Call) { canceled.add(page(call)) }
        }).build()
        val server = MockWebServer().apply {
            dispatcher = object : Dispatcher() {
                override fun dispatch(request: RecordedRequest): MockResponse =
                    // One byte starts body consumption; the missing remainder keeps each download pending.
                    MockResponse().setBody("a").setHeader("Content-Length", 100)
            }
            start()
        }
        val images = ReaderImages(context, client)
        val prefix = UUID.randomUUID().toString()
        val urls = List(9) { server.url("/$prefix/$it.png").toString() }
        // Cache the other five pages so the initial seven-page window has two pending downloads.
        (2..6).forEach { cachePage(context, urls[it]) }
        val session = ReadingSession(comic = Comic(10, "Prefetch test"),
            navigator = ReaderNavigator(listOf(Chapter(1, "Chapter", urls))), initialIndex = 0)
        val position = AtomicInteger(-1)
        val showing = mutableStateOf(true)
        try {
            compose.setContent {
                NuitComicTheme {
                    if (showing.value) ReaderScreen(session, images, position::set, { showing.value = false })
                }
            }
            compose.waitUntil(5_000) { readingBodies.containsAll(listOf(0, 1)) }

            jumpToPage(1)
            compose.waitUntil(5_000) { position.get() == 1 && canceled.contains(0) && readingBodies.contains(7) }
            assertFalse("The overlapping page must keep its original download", canceled.contains(1))
            assertEquals(1, started[1]?.get())

            jumpToPage(7)
            compose.waitUntil(5_000) { position.get() == 7 && canceled.contains(1) && readingBodies.contains(8) }
            assertFalse("A slider jump must also preserve overlapping downloads", canceled.contains(7))
            assertEquals(1, started[7]?.get())
            assertEquals(setOf(0, 1, 7, 8), started.keys)

            compose.onNodeWithContentDescription(context.getString(R.string.reader_close)).performClick()
            compose.waitUntil(5_000) { canceled.containsAll(listOf(7, 8)) }
        } finally {
            compose.runOnIdle { showing.value = false }
            client.dispatcher.cancelAll()
            server.shutdown()
            images.clearMemory()
            client.connectionPool.evictAll()
            client.dispatcher.executorService.shutdownNow()
        }
    }

    @Test fun longPageHasItsNextOffscreenStripDecodedBeforeScrolling() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        runBlocking { context.readerPreferences.edit { it[booleanPreferencesKey("horizontal")] = false } }
        val images = ReaderImages(context, OkHttpClient())
        val url = "https://example.invalid/${UUID.randomUUID()}.png"
        cachePage(context, url, height = 20_000)
        val info = runBlocking { images.info(url) }
        val session = ReadingSession(comic = Comic(11, "Long page predecode"),
            navigator = ReaderNavigator(listOf(Chapter(1, "Chapter", listOf(url)))), initialIndex = 0)
        val position = AtomicInteger(-1)
        try {
            compose.setContent {
                NuitComicTheme {
                    val density = LocalDensity.current
                    Box(Modifier.width(with(density) { 400.toDp() }).height(with(density) { 1800.toDp() })
                        .testTag("reader-viewport")) {
                        ReaderScreen(session, images, position::set, {})
                    }
                }
            }
            val viewport = compose.onNodeWithTag("reader-viewport").fetchSemanticsNode().boundsInRoot
            val width = viewport.width.roundToInt()
            val stripHeight = info.tileHeight(0, width).toFloat() * width / info.width
            val nextStrip = ceil(viewport.height / stripHeight).toInt()
            compose.waitUntil(5_000) { images.cachedTile(url, nextStrip, width) != null }
            assertEquals("Predecode must happen before the reader advances", 0, position.get())
            assertNull("The distant end of a long image must stay undecoded", images.cachedTile(url, info.tileCount(width) - 1, width))
            assertTrue("The warm strip set must remain bounded", (0 until info.tileCount(width)).count {
                images.cachedTile(url, it, width) != null
            } <= 10)
            compose.onNode(hasScrollToIndexAction()).performScrollToIndex(nextStrip)
            assertNotNull(images.cachedTile(url, nextStrip, width))
        } finally { images.clearMemory() }
    }

    @Test fun horizontalReaderDecodesUpcomingPagesBeforeTheFirstSwipe() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        runBlocking { context.readerPreferences.edit { it[booleanPreferencesKey("horizontal")] = true } }
        val images = ReaderImages(context, OkHttpClient())
        val urls = List(9) { "https://example.invalid/${UUID.randomUUID()}.png" }
        urls.forEach { cachePage(context, it) }
        val session = ReadingSession(comic = Comic(12, "Horizontal predecode"),
            navigator = ReaderNavigator(listOf(Chapter(1, "Chapter", urls))), initialIndex = 0)
        val position = AtomicInteger(-1)
        try {
            compose.setContent {
                NuitComicTheme {
                    val density = LocalDensity.current
                    Box(Modifier.width(with(density) { 400.toDp() }).height(with(density) { 1000.toDp() })
                        .testTag("reader-viewport")) {
                        ReaderScreen(session, images, position::set, {})
                    }
                }
            }
            compose.onNodeWithContentDescription(context.getString(R.string.reader_vertical)).assertIsDisplayed()
            val width = compose.onNodeWithTag("reader-viewport").fetchSemanticsNode().boundsInRoot.width.roundToInt()
            compose.waitUntil(5_000) {
                images.cachedTile(urls[1], 0, width) != null && images.cachedTile(urls[2], 0, width) != null
            }
            assertEquals("Upcoming pages must be ready before any swipe", 0, position.get())
            assertNull("A page outside the lookahead window must stay undecoded", images.cachedTile(urls[7], 0, width))
        } finally { images.clearMemory() }
    }

    @Test fun prewarmedTilePaintsOnItsFirstFrameAndDoesNotReuseThePreviousPage() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val images = ReaderImages(context, OkHttpClient())
        val urls = List(2) { "https://example.invalid/${UUID.randomUUID()}.png" }
        cachePage(context, urls[0], color = Color.BLUE)
        cachePage(context, urls[1], color = Color.GREEN)
        val info = runBlocking { urls.map { images.info(it) } }
        val selected = mutableStateOf<Int?>(null)
        try {
            compose.setContent {
                NuitComicTheme {
                    val density = LocalDensity.current
                    BoxWithConstraints(Modifier.fillMaxSize().testTag("prewarmed-viewport")) {
                        val width = minOf(400, with(density) { maxWidth.roundToPx() })
                        selected.value?.let { index ->
                            Box(Modifier.width(with(density) { width.toDp() }).testTag("prewarmed-page")) {
                                PageTile(ReaderPage(0, index, urls[index]), null, 0, width, images, false, {})
                            }
                        }
                    }
                }
            }
            val viewport = compose.onNodeWithTag("prewarmed-viewport").fetchSemanticsNode().boundsInRoot
            val width = minOf(400, viewport.width.roundToInt())
            runBlocking { urls.forEachIndexed { index, url -> images.prefetchTile(url, info[index], 0, width) } }
            compose.mainClock.autoAdvance = false
            listOf(Color.BLUE, Color.GREEN).forEachIndexed { index, color ->
                compose.runOnUiThread { selected.value = index }
                // Permit only the mounting frame, before an asynchronous cache lookup could recompose.
                compose.mainClock.advanceTimeByFrame()
                val tile = compose.onNodeWithTag("prewarmed-page").assertIsDisplayed()
                val expectedHeight = minOf(info[index].tileHeight(0, width).toFloat() * width / info[index].width,
                    viewport.height)
                assertEquals("Cached pixels must supply geometry before metadata arrives", expectedHeight,
                    tile.fetchSemanticsNode().boundsInRoot.height, 1f)
                compose.onAllNodes(SemanticsMatcher.expectValue(
                    SemanticsProperties.ProgressBarRangeInfo, ProgressBarRangeInfo.Indeterminate,
                )).assertCountEquals(0)
                val pixels = tile.captureToImage().toPixelMap()
                assertEquals("The first painted frame must contain the current page", color, pixels[pixels.width / 2, pixels.height / 2].toArgb())
            }
        } finally {
            compose.mainClock.autoAdvance = true
            compose.runOnIdle { selected.value = null }
            images.clearMemory()
        }
    }

    @Test fun shortPagesBeyondTheInitialWindowLoadWithoutScrolling() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        runBlocking { context.readerPreferences.edit { it[booleanPreferencesKey("horizontal")] = false } }
        val images = ReaderImages(context, OkHttpClient())
        val urls = List(20) { "https://example.invalid/${UUID.randomUUID()}.png" }
        urls.forEach { cachePage(context, it, height = 60) }
        val session = ReadingSession(comic = Comic(13, "Short page metadata"),
            navigator = ReaderNavigator(listOf(Chapter(1, "Chapter", urls))), initialIndex = 0)
        val position = AtomicInteger(-1)
        try {
            compose.setContent {
                NuitComicTheme {
                    val density = LocalDensity.current
                    Box(Modifier.width(with(density) { 400.toDp() }).height(with(density) { 1000.toDp() })
                        .testTag("reader-viewport")) {
                        ReaderScreen(session, images, position::set, {})
                    }
                }
            }
            val viewport = compose.onNodeWithTag("reader-viewport").fetchSemanticsNode().boundsInRoot
            val pageHeight = 60f * viewport.width / 400
            val lastVisiblePage = (ceil(viewport.height / pageHeight).toInt() - 1).coerceAtMost(urls.lastIndex)
            assertTrue("The fixture must show pages beyond the initial seven-page window", lastVisiblePage >= 7)
            compose.waitUntil(5_000) { images.cachedInfo(urls[lastVisiblePage]) != null }
            assertEquals("All visible short pages must load before scrolling", 0, position.get())
        } finally { images.clearMemory() }
    }

    private fun jumpToPage(page: Int) {
        compose.onNode(SemanticsMatcher.keyIsDefined(SemanticsActions.SetProgress))
            .performSemanticsAction(SemanticsActions.SetProgress) { it(page.toFloat()) }
    }

    private fun page(call: Call) = call.request().url.pathSegments.last().removeSuffix(".png").toInt()

    private fun cachePage(context: Context, url: String, height: Int = 600, color: Int = Color.BLUE) {
        val directory = File(context.cacheDir, "reader-pages").apply { mkdirs() }
        val file = File(directory, MessageDigest.getInstance("SHA-256").digest(url.toByteArray())
            .joinToString("") { "%02x".format(it) })
        val bitmap = Bitmap.createBitmap(400, height, Bitmap.Config.ARGB_8888)
        try {
            bitmap.eraseColor(color)
            file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        } finally { bitmap.recycle() }
    }
}
