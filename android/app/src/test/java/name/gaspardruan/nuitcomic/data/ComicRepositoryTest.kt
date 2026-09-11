package name.gaspardruan.nuitcomic.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.io.IOException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import okhttp3.OkHttpClient
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
class ComicRepositoryTest {
    private lateinit var database: ComicDatabase
    private lateinit var repository: ComicRepository
    private lateinit var source: FakeComicSource
    private var timestamp = 1_000_000L
    private val comic = Comic(42, "Moon Journey", author = "Author")

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, ComicDatabase::class.java).build()
        source = FakeComicSource()
        repository = ComicRepository(database, source, OkHttpClient()) { timestamp }
    }

    @After
    fun tearDown() {
        repository.close()
    }

    @Test
    fun collectingAndReadingUseOneRecordAndPreserveEachOther() = runBlocking {
        repository.setCollected(comic, true, 12)
        assertEquals(-1, repository.library.first().single().lastReadChapterIndex)
        repository.recordReading(comic, 3, 8, 12)
        val stored = repository.library.first().single()
        assertTrue(stored.isCollected)
        assertEquals(3, stored.lastReadChapterIndex)
        assertEquals(8, stored.lastReadPageIndex)
        repository.setCollected(comic, false, 12)
        val uncollected = repository.library.first().single()
        assertFalse(uncollected.isCollected)
        assertEquals(8, uncollected.lastReadPageIndex)
    }

    @Test
    fun removingHistoryKeepsCollectionAndRemovingCollectionKeepsHistory() = runBlocking {
        repository.setCollected(comic, true, 12)
        repository.recordReading(comic, 2, 5, 12)
        repository.removeHistory(setOf(comic.id))
        val collected = repository.library.first().single()
        assertTrue(collected.isCollected)
        assertEquals(-1, collected.lastReadChapterIndex)
        repository.recordReading(comic, 4, 7, 12)
        repository.removeCollections(setOf(comic.id))
        val history = repository.library.first().single()
        assertFalse(history.isCollected)
        assertEquals(4, history.lastReadChapterIndex)
        repository.removeHistory(setOf(comic.id))
        assertTrue(repository.library.first().isEmpty())
    }

    @Test
    fun removingAnUnreadCollectionLeavesNoPhantomHistory() = runBlocking {
        repository.setCollected(comic, true, 10)
        repository.setCollected(comic, false, 10)
        assertTrue(repository.library.first().isEmpty())
    }

    @Test
    fun concurrentCollectionAndProgressWritesDoNotLoseEitherUpdate() = runBlocking {
        coroutineScope {
            listOf(
                async { repository.setCollected(comic, true, 10) },
                async { repository.recordReading(comic, 2, 7, 10) },
            ).awaitAll()
        }
        val stored = repository.library.first().single()
        assertTrue(stored.isCollected)
        assertEquals(2, stored.lastReadChapterIndex)
        assertEquals(7, stored.lastReadPageIndex)
    }

    @Test
    fun failedRefreshPreservesUsableSearchIndexAndCanBeRetried() = runBlocking {
        source.comics = listOf(comic)
        repository.refreshSearchIndex()
        source.failure = IOException("Offline")
        repository.refreshSearchIndex(force = true)
        assertEquals(listOf(comic), repository.search("Moon"))
        assertTrue(repository.searchStatus.value.hasIndex)
        assertEquals("Offline", repository.searchStatus.value.error)
        assertFalse(repository.searchStatus.value.isRefreshing)
        source.failure = null
        source.comics = listOf(Comic(43, "New Journey"))
        timestamp++
        repository.refreshSearchIndex(force = true)
        assertEquals(listOf(43), repository.search("Journey").map { it.id })
        assertNull(repository.searchStatus.value.error)
        assertEquals(timestamp, repository.searchStatus.value.lastSyncAt)
    }

    @Test
    fun simultaneousRefreshesMakeOneNetworkRequest() = runBlocking {
        val started = CompletableDeferred<Unit>()
        val finish = CompletableDeferred<Unit>()
        source.beforeFetch = { started.complete(Unit); finish.await() }
        val first = async { repository.refreshSearchIndex() }
        started.await()
        repository.refreshSearchIndex(force = true)
        finish.complete(Unit)
        first.await()
        assertEquals(1, source.requestCount)
        assertFalse(repository.searchStatus.value.isRefreshing)
    }

    @Test
    fun recentAndEmptyIndexesDoNotRedownloadUntilExpired() = runBlocking {
        repository.refreshSearchIndex()
        assertTrue(repository.searchStatus.value.hasIndex)
        assertEquals(0, repository.searchStatus.value.comicCount)
        repository.refreshSearchIndex()
        assertEquals(1, source.requestCount)
        timestamp += 12 * 60 * 60 * 1_000L
        repository.refreshSearchIndex()
        assertEquals(2, source.requestCount)
    }

    @Test
    fun searchPrioritizesTitleThenDescriptionKeywordsAndAuthor() = runBlocking {
        source.comics = listOf(
            Comic(1, "Other", author = "月"),
            Comic(2, "Other", keyword = "月"),
            Comic(3, "Other", description = "月"),
            Comic(4, "月之旅"),
        )
        repository.refreshSearchIndex()
        assertEquals(listOf(4, 3, 2, 1), repository.search(" 月 ").map { it.id })
        assertTrue(repository.search(" ").isEmpty())
    }

    @Test
    fun searchTreatsSQLWildcardsAndQuotesAsLiteralText() = runBlocking {
        source.comics = listOf(
            Comic(1, "100% complete"), Comic(2, "1000 complete"),
            Comic(3, "under_score"), Comic(4, "underXscore"),
            Comic(5, "A 'quoted' title"), Comic(6, "A \\ path"),
        )
        repository.refreshSearchIndex()
        assertEquals(listOf(1), repository.search("100%").map { it.id })
        assertEquals(listOf(3), repository.search("under_").map { it.id })
        assertEquals(listOf(5), repository.search("'quoted'").map { it.id })
        assertEquals(listOf(6), repository.search("\\").map { it.id })
        assertTrue(repository.search("' OR 1=1 --").isEmpty())
    }

    @Test
    fun searchHistoryIsTrimmedDeduplicatedAndExplicitlyClearable() = runBlocking {
        repository.addSearchHistory("  Moon  ")
        timestamp++
        repository.addSearchHistory("moon")
        repository.addSearchHistory(" ")
        assertEquals(listOf("moon"), repository.searchHistory.first())
        repeat(35) {
            timestamp++
            repository.addSearchHistory("Query $it")
        }
        assertEquals(30, repository.searchHistory.first().size)
        assertEquals("Query 34", repository.searchHistory.first().first())
        repository.clearSearchHistory()
        assertTrue(repository.searchHistory.first().isEmpty())
    }

    @Test
    fun chapterCacheAvoidsRepeatedRequestsAndWorksOffline() = runBlocking {
        source.chapterList = listOf(Chapter(1, "Chapter 1", listOf("https://example.test/1.jpg")))
        assertEquals(source.chapterList, repository.chapters(42))
        assertEquals(source.chapterList, repository.chapters(42))
        assertEquals(1, source.chapterRequestCount)
        timestamp += 5 * 60 * 1_000L
        source.failure = IOException("Offline")
        assertEquals(source.chapterList, repository.chapters(42))
        assertEquals(2, source.chapterRequestCount)
        source.failure = null
        source.chapterList = source.chapterList + Chapter(2, "Chapter 2", listOf("https://example.test/2.jpg"))
        assertEquals(source.chapterList, repository.chapters(42))
        assertEquals(3, source.chapterRequestCount)
    }

    @Test
    fun libraryAndSearchRemainAvailableAfterDatabaseReopen() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val name = "persistence-${System.nanoTime()}.db"
        repository.close()
        database = Room.databaseBuilder(context, ComicDatabase::class.java, name).build()
        repository = ComicRepository(database, source, OkHttpClient()) { timestamp }
        try {
            source.comics = listOf(comic)
            repository.setCollected(comic, true, 12)
            repository.recordReading(comic, 3, 8, 12)
            repository.refreshSearchIndex()
            source.chapterList = listOf(Chapter(1, "Chapter 1", listOf("https://example.test/1.jpg")))
            repository.chapters(comic.id)
            repository.close()
            database = Room.databaseBuilder(context, ComicDatabase::class.java, name).build()
            source.failure = IOException("Offline")
            repository = ComicRepository(database, source, OkHttpClient()) { timestamp }
            repository.refreshSearchIndex()
            assertEquals(1, source.requestCount)
            assertEquals(listOf(comic), repository.search("Moon"))
            val stored = repository.library.first().single()
            assertTrue(stored.isCollected)
            assertEquals(8, stored.lastReadPageIndex)
            assertNotNull(repository.searchStatus.value.lastSyncAt)
            timestamp += 5 * 60 * 1_000L
            assertEquals(source.chapterList, repository.chapters(comic.id))
        } finally {
            repository.close()
            context.deleteDatabase(name)
        }
    }
}

private class FakeComicSource : ComicSource {
    var comics = emptyList<Comic>()
    var chapterList = emptyList<Chapter>()
    var chapterRequestCount = 0
    var failure: IOException? = null
    var requestCount = 0
    var beforeFetch: suspend () -> Unit = {}

    override suspend fun allComics(): List<Comic> {
        requestCount++
        beforeFetch()
        failure?.let { throw it }
        return comics
    }

    override suspend fun home() = HomeFeed(emptyMap())
    override suspend fun random() = emptyList<Comic>()
    override suspend fun list(section: HomeSection, page: Int) = emptyList<Comic>()
    override suspend fun chapters(comicID: Int): List<Chapter> {
        chapterRequestCount++
        failure?.let { throw it }
        return chapterList
    }
}
