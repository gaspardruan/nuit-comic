package name.gaspardruan.nuitcomic.data

import java.util.concurrent.TimeUnit
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import okhttp3.Call
import okhttp3.EventListener
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.Assert.assertTrue
import org.junit.Test

class HttpCancellationTest {
    @Test
    fun cancellingDuringTheBodyClosesTheCall() = runBlocking {
        val bodyStarted = CompletableDeferred<Unit>()
        val client = OkHttpClient.Builder().eventListener(object : EventListener() {
            override fun responseBodyStart(call: Call) { bodyStarted.complete(Unit) }
        }).build()
        MockWebServer().use { server ->
            server.enqueue(MockResponse().setBody("x".repeat(1_024)).throttleBody(1, 100, TimeUnit.MILLISECONDS))
            val call = client.newCall(Request.Builder().url(server.url("/slow")).build())
            val response = async { call.awaitBody() }
            withTimeout(5_000) { bodyStarted.await() }
            response.cancelAndJoin()
            withTimeout(5_000) {
                while (client.dispatcher.runningCallsCount() > 0) delay(10)
            }
            assertTrue(call.isCanceled())
            assertTrue(response.isCancelled)
        }
        client.connectionPool.evictAll()
        client.dispatcher.executorService.shutdown()
    }
}
