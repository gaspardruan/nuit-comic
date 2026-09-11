package name.gaspardruan.nuitcomic.reader

import android.app.ActivityManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapRegionDecoder
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.RectF
import android.util.LruCache
import androidx.exifinterface.media.ExifInterface
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import kotlin.math.ceil
import kotlin.math.roundToInt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import name.gaspardruan.nuitcomic.data.ServerConfig
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import kotlin.coroutines.resumeWithException

/** Metadata is retained independently from bitmaps so placeholders keep their proportions. */
data class PageInfo(val file: File, val sourceWidth: Int, val sourceHeight: Int, val orientation: Int) {
    private val rotated get() = orientation in 5..8
    val width get() = if (rotated) sourceHeight else sourceWidth
    val height get() = if (rotated) sourceWidth else sourceHeight

    fun tileCount(displayWidth: Int): Int = ceil(height.toDouble() / tileSourceHeight(displayWidth)).toInt()
    fun tileSourceHeight(displayWidth: Int): Int =
        (1536.0 * width / displayWidth.coerceAtLeast(1)).roundToInt().coerceAtLeast(1)
    fun tileHeight(tile: Int, displayWidth: Int): Int =
        minOf(tileSourceHeight(displayWidth), height - tile * tileSourceHeight(displayWidth))

    fun tileMemoryBytes(tile: Int, displayWidth: Int): Long {
        val bitmapWidth = minOf(width, displayWidth)
        val bitmapHeight = (tileHeight(tile, displayWidth).toDouble() * bitmapWidth / width)
            .roundToInt().coerceAtLeast(1)
        return bitmapWidth.toLong() * bitmapHeight * 4
    }
}

class ReaderImages(context: Context, private val client: OkHttpClient) {
    private val directory = File(context.cacheDir, "reader-pages").apply { mkdirs() }
    private val downloadPermits = Semaphore(2)
    // Slow prefetch downloads must not delay decoding pages that are already on disk.
    private val decodePermits = Semaphore(2)
    private val prefetchPermit = Semaphore(1)
    private val locks = Array(32) { Mutex() }
    private val tileLocks = Array(32) { Mutex() }
    private val metadata = LruCache<String, PageInfo>(1000)
    private val memoryBytes = ((context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
        .memoryClass.toLong() * 1024 * 1024 / 6).coerceIn(16L * 1024 * 1024, 64L * 1024 * 1024).toInt()
    private val bitmaps = object : LruCache<String, Bitmap>(memoryBytes) {
        override fun sizeOf(key: String, value: Bitmap) = value.allocationByteCount
    }
    val prefetchByteBudget: Long get() = memoryBytes / 2L

    fun cachedInfo(url: String): PageInfo? = metadata.get(url)?.takeIf { it.file.exists() }
    fun cachedTile(url: String, tile: Int, displayWidth: Int): Bitmap? =
        bitmaps.get("$url:$displayWidth:$tile")
    fun clearMemory() { bitmaps.evictAll() }

    suspend fun prefetchTile(url: String, info: PageInfo, tile: Int, displayWidth: Int) {
        if (cachedTile(url, tile, displayWidth) != null) return
        // Leave a decoding slot available for newly visible content.
        prefetchPermit.withPermit { this.tile(url, info, tile, displayWidth) }
    }

    suspend fun info(url: String): PageInfo = withContext(Dispatchers.IO) {
        cachedInfo(url)?.let { return@withContext it }
        locks[(url.hashCode() and Int.MAX_VALUE) % locks.size].withLock {
            cachedInfo(url)?.let { return@withLock it }
            val file = File(directory, MessageDigest.getInstance("SHA-256")
                .digest(url.toByteArray()).joinToString("") { "%02x".format(it) })
            if (!file.exists()) downloadPermits.withPermit {
                val temp = File.createTempFile("download-", ".tmp", directory)
                try {
                    val call = client.newCall(Request.Builder().url(url)
                        .header("Referer", ServerConfig.referer).build())
                    call.downloadTo(temp)
                    if (!temp.renameTo(file)) throw IOException("Cannot cache image")
                } finally { temp.delete() }
            }
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                file.delete()
                throw IOException("Unsupported image")
            }
            val orientation = runCatching { ExifInterface(file).getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL) }.getOrDefault(1)
            val info = PageInfo(file, bounds.outWidth, bounds.outHeight, orientation)
            metadata.put(url, info)
            file.setLastModified(System.currentTimeMillis())
            trimDisk()
            info
        }
    }

    /** Decode only a visible strip; even very long comics never allocate a full-size bitmap. */
    suspend fun tile(url: String, info: PageInfo, tile: Int, displayWidth: Int): Bitmap = withContext(Dispatchers.IO) {
        require(displayWidth > 0)
        require(tile in 0 until info.tileCount(displayWidth))
        val key = "$url:$displayWidth:$tile"
        bitmaps.get(key)?.let { return@withContext it }
        // Session metadata can outlive an evicted disk entry. Restore it before reserving a decoder.
        val availableInfo = if (info.file.exists()) info else this@ReaderImages.info(url)
        require(tile in 0 until availableInfo.tileCount(displayWidth))
        tileLocks[(key.hashCode() and Int.MAX_VALUE) % tileLocks.size].withLock {
            bitmaps.get(key)?.let { return@withLock it }
            decodePermits.withPermit { decodeTile(availableInfo, tile, displayWidth) }
                .also { bitmaps.put(key, it) }
        }
    }

    private fun decodeTile(info: PageInfo, tile: Int, displayWidth: Int): Bitmap {
        val sourceStep = info.tileSourceHeight(displayWidth)
        val orientedRect = RectF(0f, (tile * sourceStep).toFloat(), info.width.toFloat(),
            minOf(info.height, (tile + 1) * sourceStep).toFloat())
        val rotation = orientationMatrix(info.orientation)
        val full = RectF(0f, 0f, info.sourceWidth.toFloat(), info.sourceHeight.toFloat())
        rotation.mapRect(full)
        rotation.postTranslate(-full.left, -full.top)
        val inverse = Matrix()
        rotation.invert(inverse)
        inverse.mapRect(orientedRect)
        val sourceRect = Rect(orientedRect.left.roundToInt().coerceAtLeast(0),
            orientedRect.top.roundToInt().coerceAtLeast(0),
            orientedRect.right.roundToInt().coerceAtMost(info.sourceWidth),
            orientedRect.bottom.roundToInt().coerceAtMost(info.sourceHeight))
        var sample = 1
        while (info.width / (sample * 2) >= displayWidth) sample *= 2
        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        @Suppress("DEPRECATION")
        val decoder = BitmapRegionDecoder.newInstance(info.file.path, false)
            ?: throw IOException("Cannot decode image")
        val raw = try { decoder.decodeRegion(sourceRect, options) } finally { decoder.recycle() }
            ?: throw IOException("Cannot decode image region")
        val oriented = if (info.orientation in 2..8) {
            Bitmap.createBitmap(raw, 0, 0, raw.width, raw.height, orientationMatrix(info.orientation), true)
                .also { if (it !== raw) raw.recycle() }
        } else raw
        // Power-of-two decoding can retain almost four times the displayed pixel count.
        val bitmapWidth = minOf(info.width, displayWidth)
        val bitmapHeight = (info.tileHeight(tile, displayWidth).toDouble() * bitmapWidth / info.width)
            .roundToInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(oriented, bitmapWidth, bitmapHeight, true)
            .also { if (it !== oriented) oriented.recycle() }
    }

    private fun trimDisk() {
        val files = directory.listFiles()?.filter { !it.name.endsWith(".tmp") } ?: return
        var size = files.sumOf { it.length() }
        if (size < 512L * 1024 * 1024) return
        val cutoff = System.currentTimeMillis() - 300_000
        files.sortedBy { it.lastModified() }.forEach { file ->
            if (size > 384L * 1024 * 1024 && file.lastModified() < cutoff) {
                val bytes = file.length()
                if (file.delete()) size -= bytes
            }
        }
    }
}

internal fun orientationMatrix(orientation: Int): Matrix = Matrix().apply {
    when (orientation) {
        2 -> setScale(-1f, 1f)
        3 -> setRotate(180f)
        4 -> setScale(1f, -1f)
        5 -> { setRotate(90f); postScale(-1f, 1f) }
        6 -> setRotate(90f)
        7 -> { setRotate(-90f); postScale(-1f, 1f) }
        8 -> setRotate(-90f)
    }
}

private suspend fun Call.downloadTo(file: File): Unit = suspendCancellableCoroutine { continuation ->
    // Keep cancellation attached until the response body has finished streaming, not just its headers.
    continuation.invokeOnCancellation { cancel() }
    enqueue(object : Callback {
        override fun onFailure(call: Call, e: IOException) {
            if (!continuation.isCancelled) continuation.resumeWithException(e)
        }
        override fun onResponse(call: Call, response: Response) {
            try {
                response.use {
                    if (!it.isSuccessful) throw IOException("HTTP ${it.code}")
                    val body = it.body ?: throw IOException("Empty image response")
                    body.byteStream().use { input -> file.outputStream().use { output ->
                        val buffer = ByteArray(32768)
                        var total = 0L
                        while (true) {
                            val read = input.read(buffer)
                            if (read < 0) break
                            total += read
                            if (total > 100L * 1024 * 1024) throw IOException("Image exceeds 100 MiB")
                            output.write(buffer, 0, read)
                        }
                    } }
                }
                continuation.resume(Unit) { _, _, _ -> }
            } catch (error: Exception) {
                if (!continuation.isCancelled) continuation.resumeWithException(error)
            } finally {
                if (continuation.isCancelled) file.delete()
            }
        }
    })
}
