package name.gaspardruan.nuitcomic.ui

import android.content.Context
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.viewModelScope
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.io.IOException
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.job
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.data.ComicDatabase
import name.gaspardruan.nuitcomic.data.ComicRepository
import name.gaspardruan.nuitcomic.data.ComicSource
import name.gaspardruan.nuitcomic.data.HomeFeed
import name.gaspardruan.nuitcomic.data.HomeSection
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
class AppViewModelTest {
    private val mainDispatcher = UnconfinedTestDispatcher()
    private val timestamp = AtomicLong(1_000_000L)
    private lateinit var source: FakeComicSource
    private lateinit var client: OkHttpClient
    private lateinit var repository: ComicRepository
    private lateinit var viewModels: ViewModelStore
    private lateinit var viewModel: AppViewModel
    private val firstComic = Comic(1, "First book")
    private val secondComic = Comic(2, "Second book")
    private val firstChapters = listOf(Chapter(11, "First chapter", listOf("https://example.invalid/first.png")))
    private val secondChapters = listOf(Chapter(21, "Other chapter", listOf("https://example.invalid/second.png")))

    @Before
    fun setUp() {
        Dispatchers.setMain(mainDispatcher)
        source = FakeComicSource()
        client = OkHttpClient.Builder().addInterceptor { chain ->
            // The optional update check must never make a real network request in these tests.
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1)
                .code(200).message("OK").body("[]".toResponseBody("application/json".toMediaType())).build()
        }.build()
        val context = ApplicationProvider.getApplicationContext<Context>()
        val database = Room.inMemoryDatabaseBuilder(context, ComicDatabase::class.java).build()
        repository = ComicRepository(database, source, client, timestamp::get)
        viewModels = ViewModelStore()
        viewModel = ViewModelProvider(viewModels, AppViewModel.Factory(repository))[AppViewModel::class.java]
    }

    @After
    fun tearDown() {
        val scopeJob = viewModel.viewModelScope.coroutineContext.job
        viewModels.clear()
        source.finishPending()
        try {
            runBlocking { withTimeout(5_000) { scopeJob.join() } }
        } finally {
            repository.close()
            client.dispatcher.executorService.shutdownNow()
            client.connectionPool.evictAll()
            Dispatchers.resetMain()
        }
    }

    @Test
    fun uncachedDetailRemainsLoadingUntilItsChaptersArrive() = runBlocking {
        viewModel.navigate(Destination.Detail(firstComic))
        assertNull(viewModel.chapters.value.value)
        assertTrue(viewModel.chapters.value.loading)
        val request = chapterRequest(firstComic)
        assertNull(viewModel.chapters.value.value)
        assertTrue(viewModel.chapters.value.loading)

        request.response.complete(firstChapters)
        awaitChapters(firstChapters)
        assertNull(viewModel.chapters.value.error)
    }

    @Test
    fun revisitingLoadedBookImmediatelyKeepsItsChaptersDuringRefresh() = runBlocking {
        openLoaded(firstComic, firstChapters)
        viewModel.back()
        timestamp.addAndGet(5 * 60 * 1_000L)

        viewModel.navigate(Destination.Detail(firstComic))
        assertEquals(firstChapters, viewModel.chapters.value.value)
        assertFalse(viewModel.chapters.value.loading)
        val refresh = chapterRequest(firstComic)
        assertEquals(firstChapters, viewModel.chapters.value.value)
        assertFalse(viewModel.chapters.value.loading)

        val updated = firstChapters + Chapter(12, "New chapter", listOf("https://example.invalid/new.png"))
        refresh.response.complete(updated)
        awaitChapters(updated)
    }

    @Test
    fun switchingBooksClearsOldChaptersAndBackIgnoresALateCanceledResponse() = runBlocking {
        openLoaded(firstComic, firstChapters)
        viewModel.navigate(Destination.Detail(secondComic))
        assertNull(viewModel.chapters.value.value)
        assertTrue(viewModel.chapters.value.loading)
        val otherBook = chapterRequest(secondComic)
        assertNull(viewModel.chapters.value.value)
        assertTrue(viewModel.chapters.value.loading)

        viewModel.back()
        assertEquals(Destination.Detail(firstComic), viewModel.destinations.value.last())
        assertEquals(firstChapters, viewModel.chapters.value.value)
        assertFalse(viewModel.chapters.value.loading)
        otherBook.response.complete(secondChapters)
        withTimeout(5_000) { otherBook.job.join() }
        mainDispatcher.scheduler.runCurrent()
        assertEquals(firstChapters, viewModel.chapters.value.value)
        assertFalse(viewModel.chapters.value.loading)
    }

    @Test
    fun delayedRecommendationsDoNotDelayChapterReadiness() = runBlocking {
        val recommendations = CompletableDeferred<List<Comic>>()
        source.recommendations = recommendations
        openLoaded(firstComic, firstChapters)
        assertTrue(viewModel.detailRecommendations.value.loading)
        assertEquals(firstChapters, viewModel.chapters.value.value)
        assertFalse(viewModel.chapters.value.loading)

        recommendations.complete(listOf(secondComic))
        withTimeout(5_000) { viewModel.detailRecommendations.first { !it.loading } }
        assertEquals(listOf(secondComic), viewModel.detailRecommendations.value.value)
        assertEquals(firstChapters, viewModel.chapters.value.value)
    }

    @Test
    fun failedRecommendationsDoNotPreventChapterReadiness() = runBlocking {
        val recommendations = CompletableDeferred<List<Comic>>()
        source.recommendations = recommendations
        viewModel.navigate(Destination.Detail(firstComic))
        val request = chapterRequest(firstComic)
        recommendations.completeExceptionally(IOException("Recommendations unavailable"))
        withTimeout(5_000) { viewModel.detailRecommendations.first { !it.loading } }
        assertEquals("Recommendations unavailable", viewModel.detailRecommendations.value.error)
        assertTrue(viewModel.chapters.value.loading)

        request.response.complete(firstChapters)
        awaitChapters(firstChapters)
        assertNull(viewModel.chapters.value.error)
    }

    private suspend fun openLoaded(comic: Comic, chapters: List<Chapter>) {
        viewModel.navigate(Destination.Detail(comic))
        chapterRequest(comic).response.complete(chapters)
        awaitChapters(chapters)
    }

    private suspend fun chapterRequest(comic: Comic): ChapterRequest = withTimeout(5_000) {
        source.chapterRequests.receive().also { assertEquals(comic.id, it.comicID) }
    }

    private suspend fun awaitChapters(chapters: List<Chapter>) {
        withTimeout(5_000) { viewModel.chapters.first { !it.loading && it.value == chapters } }
    }
}

private class ChapterRequest(val comicID: Int, val job: Job) {
    val response = CompletableDeferred<List<Chapter>>()
}

private class FakeComicSource : ComicSource {
    val chapterRequests = Channel<ChapterRequest>(Channel.UNLIMITED)
    private val pending = CopyOnWriteArrayList<ChapterRequest>()
    private val closed = AtomicBoolean(false)
    @Volatile var recommendations: CompletableDeferred<List<Comic>>? = null

    override suspend fun home() = HomeFeed(emptyMap())
    override suspend fun allComics() = emptyList<Comic>()
    override suspend fun list(section: HomeSection, page: Int) = emptyList<Comic>()
    override suspend fun random() = recommendations?.await() ?: emptyList()

    override suspend fun chapters(comicID: Int): List<Chapter> {
        val request = ChapterRequest(comicID, currentCoroutineContext().job)
        pending += request
        if (closed.get()) request.response.complete(emptyList())
        chapterRequests.trySend(request)
        // Simulate a server response that can arrive after the caller has canceled navigation.
        return withContext(NonCancellable) { request.response.await() }
    }

    fun finishPending() {
        closed.set(true)
        pending.forEach { it.response.complete(emptyList()) }
        recommendations?.complete(emptyList())
    }
}
