package name.gaspardruan.nuitcomic.reader

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import androidx.exifinterface.media.ExifInterface
import androidx.test.core.app.ApplicationProvider
import java.io.File
import java.io.IOException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import name.gaspardruan.nuitcomic.data.ServerConfig
import okhttp3.OkHttpClient
import okhttp3.Call
import okhttp3.EventListener
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import okio.Buffer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/** Pixel assertions run on Android's real region decoder, rather than a JVM graphics shadow. */
class ReaderImagesTest {
    @get:Rule val files = TemporaryFolder()
    private lateinit var images: ReaderImages
    private lateinit var server: MockWebServer
    private lateinit var context: Context
    private lateinit var client: OkHttpClient

    @Before fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        File(context.cacheDir, "reader-pages").deleteRecursively()
        client = OkHttpClient()
        images = ReaderImages(context, client)
        server = MockWebServer().apply { start() }
    }

    @After fun tearDown() {
        images.clearMemory()
        server.shutdown()
        client.connectionPool.evictAll()
        client.dispatcher.executorService.shutdown()
    }

    @Test fun everyExifOrientationProducesTheExpectedPixels() = runBlocking {
        val width = 12
        val height = 8
        val file = imageFile(width, height)
        for (orientation in 1..8) {
            val info = PageInfo(file, width, height, orientation)
            val bitmap = images.tile("orientation-$orientation", info, 0, info.width)
            assertEquals(info.width, bitmap.width)
            assertEquals(info.height, bitmap.height)
            for (y in 0 until bitmap.height) {
                for (x in 0 until bitmap.width) {
                    val (sourceX, sourceY) = sourcePixel(x, y, width, height, orientation)
                    assertEquals("EXIF $orientation at ($x, $y)", pixel(sourceX, sourceY), bitmap.getPixel(x, y))
                }
            }
        }
    }

    @Test fun rotatedStripBoundariesUseTheCorrectSourceRegion() = runBlocking {
        val width = 4000
        val height = 8
        val file = imageFile(width, height)
        for (orientation in 5..8) {
            val info = PageInfo(file, width, height, orientation)
            assertEquals(3, info.tileCount(info.width))
            for (tile in 0 until info.tileCount(info.width)) {
                val bitmap = images.tile("strip-$orientation", info, tile, info.width)
                assertEquals(info.width, bitmap.width)
                assertEquals(info.tileHeight(tile, info.width), bitmap.height)
                for (y in listOf(0, bitmap.height / 2, bitmap.height - 1)) {
                    for (x in listOf(0, bitmap.width - 1)) {
                        val globalY = tile * info.tileSourceHeight(info.width) + y
                        val (sourceX, sourceY) = sourcePixel(x, globalY, width, height, orientation)
                        assertEquals("EXIF $orientation tile $tile at ($x, $y)",
                            pixel(sourceX, sourceY), bitmap.getPixel(x, y))
                    }
                }
            }
        }
    }

    @Test fun longPagesAllocateOnlyTheRequestedStrip() = runBlocking {
        val info = PageInfo(imageFile(256, 12000, detailed = false), 256, 12000, 1)
        val bitmap = images.tile("long-page", info, 3, 256)
        assertEquals(256, bitmap.width)
        assertEquals(1536, bitmap.height)
        assertTrue(bitmap.allocationByteCount <= 256 * 1536 * 4)
        assertTrue(bitmap.allocationByteCount < info.width * info.height)
    }

    @Test fun photosAreDownsampledToTheDisplayResolution() = runBlocking {
        val info = PageInfo(imageFile(2048, 3072, detailed = false), 2048, 3072, 1)
        val bitmap = images.tile("photo", info, 0, 256)
        assertEquals(256, bitmap.width)
        assertEquals(384, bitmap.height)
        assertTrue(bitmap.allocationByteCount <= 256 * 384 * 4)
    }

    @Test fun nonPowerOfTwoScreenWidthsDoNotWasteThePrefetchCache() = runBlocking {
        val info = PageInfo(imageFile(2048, 3072, detailed = false), 2048, 3072, 1)
        val bitmap = images.tile("photo-at-300", info, 0, 300)
        assertEquals(300, bitmap.width)
        assertEquals(450, bitmap.height)
        assertEquals(info.tileMemoryBytes(0, 300), bitmap.allocationByteCount.toLong())
        assertEquals(Color.MAGENTA, bitmap.getPixel(150, 225))
    }

    @Test fun prefetchedTilesAreReadyFromMemoryAndDoNotRequireTheSourceFile() = runBlocking {
        val info = PageInfo(imageFile(400, 800, detailed = false), 400, 800, 1)
        images.prefetchTile("prepared", info, 0, 300)
        val ready = images.cachedTile("prepared", 0, 300)
        assertEquals(300, ready?.width)
        assertTrue(info.file.delete())
        assertSame(ready, images.tile("prepared", info, 0, 300))
        assertNull(images.cachedTile("prepared", 0, 200))
        assertNull(images.cachedTile("other-page", 0, 300))
        images.clearMemory()
        assertNull(images.cachedTile("prepared", 0, 300))
        assertFalse(ready!!.isRecycled)
    }

    @Test fun simultaneousWarmupAndVisibleRequestsShareOneDecodedBitmap() = runBlocking {
        val info = PageInfo(imageFile(1024, 3072, detailed = false), 1024, 3072, 1)
        val results = coroutineScope {
            val warmup = async { images.prefetchTile("shared-tile", info, 0, 300) }
            val visible = List(6) { async { images.tile("shared-tile", info, 0, 300) } }
            warmup.await()
            visible.awaitAll()
        }
        assertTrue(results.all { it === results.first() })
        assertSame(results.first(), images.cachedTile("shared-tile", 0, 300))
    }

    @Test fun cacheSeparatesResolutionsAndDoesNotRecycleBitmapsStillInUse() = runBlocking {
        val info = PageInfo(imageFile(512, 768, detailed = false), 512, 768, 1)
        val small = images.tile("cached", info, 0, 128)
        assertSame(small, images.tile("cached", info, 0, 128))
        val large = images.tile("cached", info, 0, 256)
        assertNotSame(small, large)
        assertEquals(256, large.width)
        images.clearMemory()
        assertFalse(small.isRecycled)
        assertFalse(large.isRecycled)
        assertNotSame(small, images.tile("cached", info, 0, 128))
    }

    @Test fun simultaneousRequestsForOneImageShareADownload() = runBlocking {
        server.enqueue(MockResponse().setBody(Buffer().write(pngBytes())))
        val url = server.url("/shared.png").toString()
        val results = coroutineScope { List(8) { async { images.info(url) } }.awaitAll() }
        assertTrue(results.all { it.file == results.first().file })
        assertEquals(1, server.requestCount)
        assertEquals(ServerConfig.referer, server.takeRequest().getHeader("Referer"))
        assertSame(results.first(), images.cachedInfo(url))
    }

    @Test fun photoMetadataUsesExifDimensionsBeforeDisplayingTheImage() = runBlocking {
        val photo = files.newFile()
        val bitmap = Bitmap.createBitmap(12, 8, Bitmap.Config.ARGB_8888)
        try {
            bitmap.eraseColor(Color.CYAN)
            photo.outputStream().use { assertTrue(bitmap.compress(Bitmap.CompressFormat.JPEG, 100, it)) }
        } finally { bitmap.recycle() }
        ExifInterface(photo).apply {
            setAttribute(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_ROTATE_90.toString())
            saveAttributes()
        }
        server.enqueue(MockResponse().setBody(Buffer().write(photo.readBytes())))
        val info = images.info(server.url("/camera.jpg").toString())
        assertEquals(6, info.orientation)
        assertEquals(12, info.sourceWidth)
        assertEquals(8, info.sourceHeight)
        assertEquals(8, info.width)
        assertEquals(12, info.height)
    }

    @Test fun cancellingAStalledBodyReleasesTheDownloadAndAllowsRetry() = runBlocking {
        val bodyStarted = CountDownLatch(1)
        val observedClient = client.newBuilder().eventListener(object : EventListener() {
            override fun responseBodyStart(call: Call) { bodyStarted.countDown() }
        }).build()
        val observedImages = ReaderImages(context, observedClient)
        // Deliver one byte so OkHttp reports body consumption, then leave the remaining bytes stalled.
        server.enqueue(MockResponse().setBody("a").setHeader("Content-Length", 100))
        val url = server.url("/stalled.png").toString()
        val download = launch(Dispatchers.IO) { observedImages.info(url) }
        try {
            assertTrue("The request must reach the response body", bodyStarted.await(5, TimeUnit.SECONDS))
            withTimeout(3000) { download.cancelAndJoin() }
            withTimeout(3000) {
                while (observedClient.dispatcher.runningCallsCount() != 0) delay(10)
            }
            assertNull(observedImages.cachedInfo(url))
            assertTrue(File(context.cacheDir, "reader-pages").listFiles().orEmpty().isEmpty())
            server.enqueue(MockResponse().setBody(Buffer().write(pngBytes())))
            assertEquals(12, withTimeout(3000) { observedImages.info(url) }.width)
        } finally {
            download.cancel()
            observedImages.clearMemory()
        }
    }

    @Test fun invalidTileRequestsAreRejectedBeforeAttemptingToDecode() {
        val info = PageInfo(File("missing-image"), 400, 600, 1)
        for ((tile, width) in listOf(0 to 0, 0 to -1, -1 to 400, 1 to 400)) {
            assertThrows(IllegalArgumentException::class.java) {
                runBlocking { images.tile("invalid", info, tile, width) }
            }
        }
    }

    @Test fun deletingADiskEntryInvalidatesItsMetadataAndDownloadsAgain() = runBlocking {
        repeat(2) { server.enqueue(MockResponse().setBody(Buffer().write(pngBytes()))) }
        val url = server.url("/evicted.png").toString()
        val original = images.info(url)
        assertTrue(original.file.delete())
        assertNull(images.cachedInfo(url))
        assertTrue(images.info(url).file.exists())
        assertEquals(2, server.requestCount)
    }

    @Test fun returningToAnEvictedPageRestoresItsPixelsFromExistingSessionMetadata() = runBlocking {
        val body = pngBytes()
        repeat(2) { server.enqueue(MockResponse().setBody(Buffer().write(body))) }
        val url = server.url("/return-to-evicted.png").toString()
        val oldInfo = images.info(url)
        val original = images.tile(url, oldInfo, 0, 12)
        assertTrue(oldInfo.file.delete())
        images.clearMemory()
        assertNull(images.cachedTile(url, 0, 12))

        // ReaderScreen retains oldInfo while both warmup and visible tiles may request this page again.
        val restored = withTimeout(5_000) {
            coroutineScope {
                val warmup = async { images.prefetchTile(url, oldInfo, 0, 12) }
                val visible = List(6) { async { images.tile(url, oldInfo, 0, 12) } }
                warmup.await()
                visible.awaitAll()
            }
        }
        assertTrue(oldInfo.file.exists())
        assertEquals(2, server.requestCount)
        assertTrue(restored.all { it === restored.first() })
        assertNotSame(original, restored.first())
        assertSame(restored.first(), images.cachedTile(url, 0, 12))
        for (y in 0 until 8) {
            for (x in 0 until 12) assertEquals(pixel(x, y), restored.first().getPixel(x, y))
        }
    }

    @Test fun invalidImageResponsesCanBeRetriedWithoutKeepingCorruptCacheFiles() = runBlocking {
        server.enqueue(MockResponse().setBody("<html>Service unavailable</html>"))
        server.enqueue(MockResponse().setBody(Buffer().write(pngBytes())))
        val url = server.url("/retry.png").toString()
        assertThrows(IOException::class.java) { runBlocking { images.info(url) } }
        assertNull(images.cachedInfo(url))
        assertTrue(File(context.cacheDir, "reader-pages").listFiles().orEmpty().isEmpty())
        assertEquals(12, images.info(url).width)
        assertEquals(2, server.requestCount)
    }

    @Test fun failedHttpRequestsDoNotLeaveTemporaryFiles() = runBlocking {
        server.enqueue(MockResponse().setResponseCode(503).setBody("Unavailable"))
        val url = server.url("/unavailable.png").toString()
        val error = assertThrows(IOException::class.java) { runBlocking { images.info(url) } }
        assertTrue(error.message.orEmpty().contains("503"))
        assertNull(images.cachedInfo(url))
        assertTrue(File(context.cacheDir, "reader-pages").listFiles().orEmpty().isEmpty())
    }

    @Test fun networkConcurrencyIsBounded() = runBlocking {
        val active = AtomicInteger()
        val maximum = AtomicInteger()
        val body = pngBytes()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val current = active.incrementAndGet()
                maximum.updateAndGet { maxOf(it, current) }
                try {
                    Thread.sleep(60)
                    return MockResponse().setBody(Buffer().write(body))
                } finally {
                    active.decrementAndGet()
                }
            }
        }
        coroutineScope {
            List(6) { index -> async { images.info(server.url("/$index.png").toString()) } }.awaitAll()
        }
        assertEquals(6, server.requestCount)
        assertTrue(maximum.get() in 1..2)
    }

    @Test fun loadedPageDecodesWhilePrefetchDownloadsAreStalled() = runBlocking {
        val bodyStarted = CountDownLatch(2)
        val observedClient = client.newBuilder().eventListener(object : EventListener() {
            override fun responseBodyStart(call: Call) { bodyStarted.countDown() }
        }).build()
        val observedImages = ReaderImages(context, observedClient)
        val info = PageInfo(imageFile(12, 8), 12, 8, 1)
        repeat(2) { server.enqueue(MockResponse().setBody("a").setHeader("Content-Length", 100)) }
        val downloads = List(2) { index -> launch(Dispatchers.IO) {
            observedImages.info(server.url("/slow-$index.png").toString())
        } }
        try {
            assertTrue("Both prefetch requests must be reading their bodies", bodyStarted.await(5, TimeUnit.SECONDS))
            val bitmap = withTimeout(3000) { observedImages.tile("visible-page", info, 0, 12) }
            assertEquals(pixel(5, 3), bitmap.getPixel(5, 3))
            assertTrue("Decoding must finish before either download", downloads.all { it.isActive })
        } finally {
            downloads.forEach { it.cancelAndJoin() }
            withTimeout(3000) {
                while (observedClient.dispatcher.runningCallsCount() != 0) delay(10)
            }
            observedImages.clearMemory()
        }
    }

    private fun imageFile(width: Int, height: Int, detailed: Boolean = true): File {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        try {
            if (detailed) {
                val pixels = IntArray(width * height) { index -> pixel(index % width, index / width) }
                bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
            } else bitmap.eraseColor(Color.MAGENTA)
            return files.newFile().also { file ->
                file.outputStream().use { assertTrue(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)) }
            }
        } finally {
            bitmap.recycle()
        }
    }

    private fun pngBytes(): ByteArray = imageFile(12, 8).readBytes()

    private fun pixel(x: Int, y: Int): Int = Color.rgb(x % 251, (y * 23) % 251, (x * 13 + y * 7) % 251)

    private fun sourcePixel(x: Int, y: Int, width: Int, height: Int, orientation: Int): Pair<Int, Int> =
        when (orientation) {
            2 -> (width - 1 - x) to y
            3 -> (width - 1 - x) to (height - 1 - y)
            4 -> x to (height - 1 - y)
            5 -> y to x
            6 -> y to (height - 1 - x)
            7 -> (width - 1 - y) to (height - 1 - x)
            8 -> (width - 1 - y) to x
            else -> x to y
        }
}
