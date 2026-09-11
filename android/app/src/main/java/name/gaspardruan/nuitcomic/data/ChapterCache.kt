package name.gaspardruan.nuitcomic.data

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.put

internal object ChapterCache {
    fun encode(chapters: List<Chapter>): String = JsonArray(chapters.map { chapter ->
        buildJsonObject {
            put("id", chapter.id)
            put("title", chapter.title)
            put("imagelist", JsonArray(chapter.images.map(::JsonPrimitive)))
        }
    }).toString()

    fun decode(json: String): List<Chapter> = Json.parseToJsonElement(json).jsonArray.map(ComicJson::chapter)
}
