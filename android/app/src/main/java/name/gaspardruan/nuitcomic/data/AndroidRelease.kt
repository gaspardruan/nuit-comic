package name.gaspardruan.nuitcomic.data

import java.io.IOException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import okhttp3.OkHttpClient
import okhttp3.Request

data class AndroidRelease(val version: String, val notes: String, val url: String)

internal suspend fun fetchAndroidRelease(client: OkHttpClient): AndroidRelease? = withContext(Dispatchers.IO) {
    val request = Request.Builder()
        .url("https://api.github.com/repos/gaspardruan/nuit-comic/releases?per_page=30")
        .header("Accept", "application/vnd.github+json")
        .header("X-GitHub-Api-Version", "2022-11-28")
        .build()
    AndroidReleaseJson.parse(Json.parseToJsonElement(client.newCall(request).awaitBody()))
}

internal object AndroidReleaseJson {
    fun parse(element: JsonElement): AndroidRelease? {
        val releases = element as? JsonArray ?: throw IOException("Unexpected GitHub release response.")
        return releases.firstNotNullOfOrNull { value ->
            val release = value as? JsonObject ?: return@firstNotNullOfOrNull null
            if (release.text("draft") == "true" || release.text("prerelease") == "true") {
                return@firstNotNullOfOrNull null
            }
            val assets = release["assets"] as? JsonArray ?: return@firstNotNullOfOrNull null
            val hasAPK = assets.any { asset ->
                (asset as? JsonObject)?.text("name")?.endsWith(".apk", ignoreCase = true) == true
            }
            val version = release.text("tag_name").removePrefix("v")
            if (!hasAPK || !version.matches(Regex("[0-9]+\\.[0-9]+\\.[0-9]+"))) {
                return@firstNotNullOfOrNull null
            }
            AndroidRelease(version, release.text("body"), release.text("html_url"))
        }
    }

    private fun JsonObject.text(key: String): String = (get(key) as? JsonPrimitive)?.contentOrNull.orEmpty()
}
