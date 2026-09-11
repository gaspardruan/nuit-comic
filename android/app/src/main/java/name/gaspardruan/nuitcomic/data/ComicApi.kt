package name.gaspardruan.nuitcomic.data

import java.io.IOException
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import okhttp3.Call
import okhttp3.Callback
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response

internal interface ComicSource {
    suspend fun home(): HomeFeed
    suspend fun random(): List<Comic>
    suspend fun list(section: HomeSection, page: Int): List<Comic>
    suspend fun chapters(comicID: Int): List<Chapter>
    suspend fun allComics(): List<Comic>
}

internal class ComicApi(
    private val client: OkHttpClient,
    private val baseUrl: String = ServerConfig.apiBaseUrl,
) : ComicSource {
    override suspend fun home(): HomeFeed = coroutineScope {
        val featured = async { request("/yymhindex.html").obj("data") }
        val updated = async { bookList("update_time desc", 0, 6) }
        val mostRead = async { bookList("view desc", 0, 6) }
        val mostFollowed = async { bookList("mark desc", 0, 6) }
        val completed = async { bookList("view desc", 0, 6, completed = true) }
        val mostSearched = async { rankedComics().take(9) }
        val index = featured.await()
        HomeFeed(
            linkedMapOf(
                HomeSection.NEW to (index.obj("jphc1").comics("data") +
                    index.obj("jphc2").comics("data")).distinctBy { it.id },
                HomeSection.UPDATED to updated.await(),
                HomeSection.RECOMMENDED to (index.obj("rmtj1").comics("data") +
                    index.obj("rmtj2").comics("data")).distinctBy { it.id },
                HomeSection.MOST_READ to mostRead.await(),
                HomeSection.MOST_FOLLOWED to mostFollowed.await(),
                HomeSection.COMPLETED to completed.await(),
                HomeSection.MOST_SEARCHED to mostSearched.await(),
            )
        )
    }

    override suspend fun random(): List<Comic> =
        request("/getcnxh.html", mapOf("limit" to "6")).comics("data")

    override suspend fun list(section: HomeSection, page: Int): List<Comic> {
        require(page >= 1) { "Pages start at 1." }
        val start = (page - 1) * ServerConfig.pageSize
        return when (section) {
            HomeSection.RECOMMENDED -> request("/getpage/tp/1-recommend-$page")
                .obj("result").comics("list")
            HomeSection.MOST_SEARCHED -> rankedComics().drop(start).take(ServerConfig.pageSize)
            else -> bookList(
                order = when (section) {
                    HomeSection.NEW -> "id desc"
                    HomeSection.UPDATED -> "update_time desc"
                    HomeSection.MOST_FOLLOWED -> "mark desc"
                    else -> "view desc"
                },
                start = start,
                limit = ServerConfig.pageSize,
                completed = section == HomeSection.COMPLETED,
            )
        }
    }

    override suspend fun chapters(comicID: Int): List<Chapter> =
        request("/chapter_list/tp/$comicID-1-1-1000").obj("result").array("list")
            .map { ComicJson.chapter(it) }.distinctBy { it.id }

    override suspend fun allComics(): List<Comic> =
        request("/getbook.html", emptyMap()).comics("data")

    private suspend fun rankedComics(): List<Comic> =
        request("/rank/type/1").obj("result").comics("most_search")

    private suspend fun bookList(
        order: String,
        start: Int,
        limit: Int,
        completed: Boolean = false,
    ): List<Comic> {
        val parameters = mutableMapOf(
            "start" to "$start", "limit" to "$limit", "type" to "1", "order" to order
        )
        if (completed) parameters["mhstatus"] = "1"
        return request("/getbook.html", parameters).comics("data")
    }

    private suspend fun request(path: String, form: Map<String, String>? = null): JsonObject =
        withContext(Dispatchers.IO) {
            val builder = Request.Builder().url(baseUrl + path)
                .header("Referer", ServerConfig.referer)
            if (form != null) {
                val body = FormBody.Builder()
                form.forEach { (key, value) -> body.add(key, value) }
                builder.post(body.build())
            }
            val payload = client.newCall(builder.build()).awaitBody()
            Json.parseToJsonElement(payload) as? JsonObject
                ?: throw IOException("The server returned an unexpected response.")
        }
}

internal fun defaultHttpClient(): OkHttpClient = OkHttpClient.Builder()
    .connectTimeout(15, TimeUnit.SECONDS)
    .readTimeout(30, TimeUnit.SECONDS)
    .callTimeout(60, TimeUnit.SECONDS)
    .addInterceptor { chain ->
        chain.proceed(chain.request().newBuilder().header("Referer", ServerConfig.referer).build())
    }
    .build()

internal suspend fun Call.awaitBody(): String = suspendCancellableCoroutine { continuation ->
    // Cancellation stays attached while the body is being read, not just until headers arrive.
    continuation.invokeOnCancellation { cancel() }
    enqueue(object : Callback {
        override fun onFailure(call: Call, error: IOException) {
            if (!continuation.isCancelled) continuation.resumeWithException(error)
        }

        override fun onResponse(call: Call, response: Response) {
            try {
                val text = response.use {
                    if (!it.isSuccessful) throw IOException("Server request failed (HTTP ${it.code}).")
                    it.body?.string() ?: throw IOException("The server returned an empty response.")
                }
                continuation.resume(text)
            } catch (error: IOException) {
                if (!continuation.isCancelled) continuation.resumeWithException(error)
            }
        }
    })
}

internal object ComicJson {
    private val dateFormat = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
    private val serverTimeZone = ZoneId.of("Asia/Shanghai")

    fun comic(value: JsonElement): Comic {
        val item = value as? JsonObject ?: throw IOException("Invalid comic record.")
        return Comic(
            id = item.requiredID(),
            title = item.text("title"),
            image = ServerConfig.imageUrl(item.text("image")),
            cover = ServerConfig.imageUrl(item.text("cover")),
            description = item.text("desc"),
            author = item.text("auther"),
            keyword = item.text("keyword"),
            follow = item.text("mark").toIntOrNull() ?: 0,
            view = item.text("view").toLongOrNull() ?: 0,
            isOver = item.text("mhstatus") == "1",
            score = item.text("pingfen").toDoubleOrNull() ?: 9.0,
            updateTime = parseDate(item.text("update_time")),
        )
    }

    fun chapter(value: JsonElement): Chapter {
        val item = value as? JsonObject ?: throw IOException("Invalid chapter record.")
        val images = when (val list = item["imagelist"]) {
            is JsonArray -> list.mapNotNull { (it as? JsonPrimitive)?.contentOrNull }
            is JsonPrimitive -> list.contentOrNull.orEmpty().split(',')
            else -> emptyList()
        }
        return Chapter(
            id = item.requiredID(),
            title = item.text("title"),
            images = images.map { it.trim() }.filter { it.isNotEmpty() }
                .map(ServerConfig::imageUrl),
        )
    }

    private fun parseDate(value: String): Long = try {
        LocalDateTime.parse(value, dateFormat).atZone(serverTimeZone).toInstant().toEpochMilli()
    } catch (_: DateTimeParseException) {
        0
    }
}

private fun JsonObject.text(key: String): String =
    (get(key) as? JsonPrimitive)?.takeUnless { it == JsonNull }?.contentOrNull.orEmpty()

private fun JsonObject.requiredID(): Int = text("id").toIntOrNull()?.takeIf { it > 0 }
    ?: throw IOException("The server returned an invalid record ID.")

private fun JsonObject.obj(key: String): JsonObject = get(key) as? JsonObject
    ?: throw IOException("The server response is missing '$key'.")

private fun JsonObject.array(key: String): JsonArray = get(key) as? JsonArray
    ?: throw IOException("The server response is missing '$key'.")

private fun JsonObject.comics(key: String): List<Comic> =
    array(key).map(ComicJson::comic).distinctBy { it.id }
