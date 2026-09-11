package name.gaspardruan.nuitcomic.data

import java.io.IOException
import java.util.Collections
import kotlinx.coroutines.runBlocking
import okhttp3.FormBody
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ComicApiTest {
    private val requests = Collections.synchronizedList(mutableListOf<Request>())

    private fun api(response: (Request) -> Pair<Int, String>): ComicApi {
        val client = OkHttpClient.Builder().addInterceptor { chain ->
            val request = chain.request()
            requests.add(request)
            val (status, text) = response(request)
            Response.Builder().request(request).protocol(Protocol.HTTP_1_1)
                .code(status).message("Fixture")
                .body(text.toResponseBody("application/json".toMediaType())).build()
        }.build()
        return ComicApi(client, "https://example.test/home/api")
    }

    @Test
    fun completedListUsesPOSTFormAndZeroBasedOffset() = runBlocking {
        val api = api { 200 to """{"data":[]}""" }
        api.list(HomeSection.COMPLETED, 2)
        val request = requests.single()
        val form = request.body as FormBody
        val values = (0 until form.size).associate { form.name(it) to form.value(it) }
        assertEquals("POST", request.method)
        assertEquals("/home/api/getbook.html", request.url.encodedPath)
        assertEquals(ServerConfig.referer, request.header("Referer"))
        assertEquals(mapOf("start" to "20", "limit" to "20", "type" to "1", "order" to "view desc", "mhstatus" to "1"), values)
    }

    @Test
    fun fullSearchIndexUsesUnfilteredPOST() = runBlocking {
        api { 200 to """{"data":[{"id":"1","title":"Index"}]}""" }.allComics()
        val request = requests.single()
        assertEquals("POST", request.method)
        assertEquals(0, (request.body as FormBody).size)
    }

    @Test
    fun recommendationsUseThePagedGETEndpoint() = runBlocking {
        api { 200 to """{"result":{"list":[]}}""" }.list(HomeSection.RECOMMENDED, 3)
        assertEquals("/home/api/getpage/tp/1-recommend-3", requests.single().url.encodedPath)
        assertEquals("GET", requests.single().method)
        assertNull(requests.single().body)
    }

    @Test
    fun homeCombinesBothFeaturedGroupsAndFetchesAllSections() = runBlocking {
        val api = api { request ->
            200 to when (request.url.encodedPath.substringAfter("/api")) {
                "/yymhindex.html" -> """{"data":{
                    "jphc1":{"data":[{"id":1,"title":"One"}]},"jphc2":{"data":[{"id":2,"title":"Two"}]},
                    "rmtj1":{"data":[{"id":3,"title":"Three"}]},"rmtj2":{"data":[{"id":4,"title":"Four"}]}}}"""
                "/rank/type/1" -> """{"result":{"most_search":[]}}"""
                else -> """{"data":[]}"""
            }
        }
        val home = api.home()
        assertEquals(HomeSection.entries.toSet(), home.sections.keys)
        assertEquals(listOf(1, 2), home.sections.getValue(HomeSection.NEW).map { it.id })
        assertEquals(listOf(3, 4), home.sections.getValue(HomeSection.RECOMMENDED).map { it.id })
        assertEquals(6, requests.size)
    }

    @Test
    fun malformedResponseIsAnErrorRatherThanAnEmptySuccessfulIndex() = runBlocking {
        try {
            api { 200 to """{"error":"temporarily unavailable"}""" }.allComics()
            throw AssertionError("Expected invalid response failure")
        } catch (expected: IOException) {
            assertTrue(expected.message.orEmpty().contains("data"))
        }
    }

    @Test
    fun httpErrorsAreReportedWithoutTryingToDecodeHTML() = runBlocking {
        try {
            api { 503 to "<html>Unavailable</html>" }.random()
            throw AssertionError("Expected HTTP failure")
        } catch (expected: IOException) {
            assertTrue(expected.message.orEmpty().contains("503"))
        }
    }
}
