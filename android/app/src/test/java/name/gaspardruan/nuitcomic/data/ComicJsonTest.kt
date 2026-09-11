package name.gaspardruan.nuitcomic.data

import java.io.IOException
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ComicJsonTest {
    @Test
    fun mapsServerNamesAndStringNumbers() {
        val comic = ComicJson.comic(Json.parseToJsonElement("""
            {"id":"42","title":"Sample","image":"/cover.jpg","cover":"/wide.jpg",
             "desc":"Description","auther":"Author","keyword":"adventure","mark":"12",
             "view":"3000000000","mhstatus":"1","pingfen":"9.5","update_time":"2026-01-01 08:00:00"}
        """))
        assertEquals(42, comic.id)
        assertEquals("Description", comic.description)
        assertEquals("Author", comic.author)
        assertEquals(12, comic.follow)
        assertEquals(3_000_000_000L, comic.view)
        assertTrue(comic.isOver)
        assertEquals(9.5, comic.score, 0.0)
        assertEquals(1_767_225_600_000L, comic.updateTime)
        assertEquals("${ServerConfig.imageBaseUrl}/cover.jpg", comic.coverUrl)
    }

    @Test
    fun permitsNumericFieldsAndMissingOptionalMetadata() {
        val comic = ComicJson.comic(Json.parseToJsonElement("""{"id":42,"title":"Sample","mark":5,"view":null}"""))
        assertEquals(5, comic.follow)
        assertEquals(0L, comic.view)
        assertEquals(9.0, comic.score, 0.0)
        assertFalse(comic.isOver)
        assertEquals("", comic.coverUrl)
    }

    @Test(expected = IOException::class)
    fun invalidIDsFailBeforeAnIndexCanBeReplaced() {
        ComicJson.comic(Json.parseToJsonElement("""{"id":"invalid","title":"Sample"}"""))
    }

    @Test
    fun trimsChapterImagesAndPreservesAbsoluteURLs() {
        val chapter = ComicJson.chapter(Json.parseToJsonElement("""
            {"id":"7","title":"Chapter 1","imagelist":" /one.jpg, ,https://images.example/two.jpg,\n//images.example/three.jpg,"}
        """))
        assertEquals(listOf(
            "${ServerConfig.imageBaseUrl}/one.jpg",
            "https://images.example/two.jpg",
            "https://images.example/three.jpg",
        ), chapter.images)
    }

    @Test
    fun emptyChaptersAreValidAndDoNotCreateBlankImageRequests() {
        assertTrue(ComicJson.chapter(Json.parseToJsonElement("""{"id":7,"title":"Pending","imagelist":" , "}""")).images.isEmpty())
    }

    @Test
    fun imageURLPreservesTheServerPublicPrefix() {
        assertEquals("${ServerConfig.imageBaseUrl}/public/image.jpg", ServerConfig.imageUrl("/public/image.jpg"))
        assertEquals("", ServerConfig.imageUrl(" "))
    }
}
