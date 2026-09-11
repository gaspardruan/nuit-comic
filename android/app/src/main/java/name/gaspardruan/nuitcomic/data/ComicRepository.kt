package name.gaspardruan.nuitcomic.data

import android.content.Context
import android.util.LruCache
import androidx.room.Room
import androidx.room.withTransaction
import java.io.Closeable
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient

class ComicRepository internal constructor(
    private val database: ComicDatabase,
    private val source: ComicSource,
    val client: OkHttpClient,
    private val now: () -> Long = System::currentTimeMillis,
) : Closeable {
    constructor(context: Context) : this(context.applicationContext, defaultHttpClient())

    private constructor(context: Context, client: OkHttpClient) : this(
        Room.databaseBuilder(context, ComicDatabase::class.java, "nuitcomic.db").build(),
        ComicApi(client),
        client,
    )

    private val dao = database.comics()
    private val chapterMemory = LruCache<Int, List<Chapter>>(5)
    private val refreshMutex = Mutex()
    private val mutableSearchStatus = MutableStateFlow(SearchStatus())
    val searchStatus: StateFlow<SearchStatus> = mutableSearchStatus.asStateFlow()
    val library: Flow<List<StoredComic>> = dao.library().map { entries -> entries.map { it.toStoredComic() } }
    val searchHistory: Flow<List<String>> = dao.searchHistory()

    suspend fun home(): HomeFeed = source.home()
    suspend fun random(): List<Comic> = source.random()
    suspend fun list(section: HomeSection, page: Int): List<Comic> = source.list(section, page)

    // Recently opened books can enable reading immediately while their stored cache is refreshed.
    fun cachedChapters(comicID: Int): List<Chapter>? = chapterMemory.get(comicID)

    suspend fun chapters(comicID: Int): List<Chapter> = withContext(Dispatchers.IO) {
        val cached = dao.cachedChapters(comicID)
        if (cached != null && now() - cached.fetchedAt in 0 until CHAPTER_CACHE_AGE) {
            return@withContext ChapterCache.decode(cached.chapters)
        }
        val chapters = try {
            source.chapters(comicID)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Exception) {
            // Previously opened chapters remain available when the server cannot be reached.
            return@withContext cached?.let { ChapterCache.decode(it.chapters) } ?: throw error
        }
        val encoded = ChapterCache.encode(chapters)
        database.withTransaction {
            dao.saveChapterCache(ChapterCacheEntry(comicID, encoded, now()))
            dao.trimChapterCache()
        }
        chapters
    }.also { chapterMemory.put(comicID, it) }
    suspend fun latestAndroidRelease(): AndroidRelease? = fetchAndroidRelease(client)

    suspend fun setCollected(comic: Comic, collected: Boolean, chapterCount: Int) {
        database.withTransaction {
            val current = dao.libraryEntry(comic.id)
            if (!collected && (current == null || current.lastReadChapterIndex < 0)) {
                dao.deleteLibraryEntry(comic.id)
            } else {
                dao.saveLibraryEntry(
                    LibraryEntry(
                        id = comic.id,
                        comic = comic,
                        isCollected = collected,
                        lastReadChapterIndex = current?.lastReadChapterIndex ?: -1,
                        lastReadPageIndex = current?.lastReadPageIndex ?: 0,
                        chapterCount = chapterCount.coerceAtLeast(current?.chapterCount ?: 0),
                        updatedAt = current?.updatedAt ?: now(),
                    )
                )
            }
        }
    }

    suspend fun recordReading(comic: Comic, chapterIndex: Int, pageIndex: Int, chapterCount: Int) {
        require(chapterCount > 0 && chapterIndex in 0 until chapterCount && pageIndex >= 0) {
            "Reading progress must refer to an existing chapter and a non-negative page."
        }
        database.withTransaction {
            val current = dao.libraryEntry(comic.id)
            dao.saveLibraryEntry(
                LibraryEntry(
                    id = comic.id,
                    comic = comic,
                    isCollected = current?.isCollected ?: false,
                    lastReadChapterIndex = chapterIndex,
                    lastReadPageIndex = pageIndex,
                    chapterCount = chapterCount,
                    updatedAt = now(),
                )
            )
        }
    }

    suspend fun removeHistory(ids: Set<Int>) {
        database.withTransaction {
            ids.toList().chunked(500).forEach { batch ->
                dao.deleteUncollectedHistory(batch)
                dao.clearProgress(batch)
            }
        }
    }

    suspend fun removeCollections(ids: Set<Int>) {
        database.withTransaction {
            ids.toList().chunked(500).forEach { batch ->
                dao.deleteUnreadCollections(batch)
                dao.clearCollectionFlag(batch)
            }
        }
    }

    suspend fun addSearchHistory(query: String) {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return
        database.withTransaction {
            dao.saveSearchHistory(SearchHistoryEntry(trimmed, now()))
            dao.trimSearchHistory()
        }
    }

    suspend fun clearSearchHistory() = dao.clearSearchHistory()

    suspend fun refreshSearchIndex(force: Boolean = false) {
        // Only one refresh downloads and replaces the index at a time.
        if (!refreshMutex.tryLock()) return
        mutableSearchStatus.update { it.copy(isRefreshing = true, error = null) }
        try {
            val previous = readSearchStatus()
            mutableSearchStatus.value = previous.copy(isRefreshing = true)
            val lastSync = previous.lastSyncAt
            if (!force && lastSync != null && now() - lastSync in 0 until SEARCH_MAX_AGE) return

            // Download and decode first. A failure never deletes the last usable index.
            val comics = source.allComics()
            database.withTransaction {
                dao.clearSearchIndex()
                comics.chunked(200).forEach { batch ->
                    dao.insertSearchComics(batch.map { SearchComicEntry(it.id, it) })
                }
                dao.saveSearchMetadata(SearchMetadata(lastSyncAt = now()))
            }
            mutableSearchStatus.value = readSearchStatus().copy(isRefreshing = true)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Exception) {
            mutableSearchStatus.update { it.copy(error = error.message ?: error.javaClass.simpleName) }
        } finally {
            mutableSearchStatus.update { it.copy(isRefreshing = false) }
            refreshMutex.unlock()
        }
    }

    suspend fun search(query: String): List<Comic> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return emptyList()
        val escaped = trimmed.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        return dao.search("%$escaped%").map { it.comic }
    }

    private suspend fun readSearchStatus(): SearchStatus = database.withTransaction {
        val count = dao.searchComicCount()
        val metadata = dao.searchMetadata()
        SearchStatus(hasIndex = count > 0 || metadata != null, comicCount = count, lastSyncAt = metadata?.lastSyncAt)
    }

    override fun close() {
        database.close()
    }

    private companion object {
        const val SEARCH_MAX_AGE = 12 * 60 * 60 * 1_000L
        const val CHAPTER_CACHE_AGE = 3 * 60 * 1_000L
    }
}
