package name.gaspardruan.nuitcomic.data

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.RoomDatabase
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "library")
internal data class LibraryEntry(
    @PrimaryKey val id: Int,
    @Embedded(prefix = "comic_") val comic: Comic,
    val isCollected: Boolean,
    val lastReadChapterIndex: Int,
    val lastReadPageIndex: Int,
    val chapterCount: Int,
    val updatedAt: Long,
) {
    fun toStoredComic() = StoredComic(
        comic, isCollected, lastReadChapterIndex, lastReadPageIndex, chapterCount, updatedAt
    )
}

@Entity(tableName = "search_comics")
internal data class SearchComicEntry(
    @PrimaryKey val id: Int,
    @Embedded(prefix = "comic_") val comic: Comic,
)

@Entity(tableName = "search_metadata")
internal data class SearchMetadata(@PrimaryKey val id: Int = 1, val lastSyncAt: Long)

@Entity(tableName = "chapter_cache")
internal data class ChapterCacheEntry(@PrimaryKey val comicID: Int, val chapters: String, val fetchedAt: Long)

@Entity(tableName = "search_history")
internal data class SearchHistoryEntry(
    @PrimaryKey @ColumnInfo(collate = ColumnInfo.NOCASE) val query: String,
    val updatedAt: Long,
)

@Dao
internal interface ComicDao {
    @Query("SELECT * FROM chapter_cache WHERE comicID = :comicID")
    suspend fun cachedChapters(comicID: Int): ChapterCacheEntry?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveChapterCache(entry: ChapterCacheEntry)

    @Query(
        "DELETE FROM chapter_cache WHERE comicID NOT IN " +
            "(SELECT comicID FROM chapter_cache ORDER BY fetchedAt DESC, comicID DESC LIMIT 20)"
    )
    suspend fun trimChapterCache()

    @Query("SELECT * FROM library ORDER BY updatedAt DESC, id DESC")
    fun library(): Flow<List<LibraryEntry>>

    @Query("SELECT * FROM library WHERE id = :id")
    suspend fun libraryEntry(id: Int): LibraryEntry?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveLibraryEntry(entry: LibraryEntry)

    @Query("DELETE FROM library WHERE id = :id")
    suspend fun deleteLibraryEntry(id: Int)

    @Query("DELETE FROM library WHERE id IN (:ids) AND isCollected = 0")
    suspend fun deleteUncollectedHistory(ids: List<Int>)

    @Query("UPDATE library SET lastReadChapterIndex = -1, lastReadPageIndex = 0 WHERE id IN (:ids)")
    suspend fun clearProgress(ids: List<Int>)

    @Query("DELETE FROM library WHERE id IN (:ids) AND lastReadChapterIndex < 0")
    suspend fun deleteUnreadCollections(ids: List<Int>)

    @Query("UPDATE library SET isCollected = 0 WHERE id IN (:ids)")
    suspend fun clearCollectionFlag(ids: List<Int>)

    @Query("SELECT COUNT(*) FROM search_comics")
    suspend fun searchComicCount(): Int

    @Query("SELECT * FROM search_metadata WHERE id = 1")
    suspend fun searchMetadata(): SearchMetadata?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveSearchMetadata(metadata: SearchMetadata)

    @Query("DELETE FROM search_comics")
    suspend fun clearSearchIndex()

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSearchComics(comics: List<SearchComicEntry>)

    // Literal substring matching works with Chinese text and punctuation on Android's SQLite.
    @Query(
        """
        SELECT * FROM search_comics
        WHERE comic_title LIKE :pattern ESCAPE '\'
           OR comic_description LIKE :pattern ESCAPE '\'
           OR comic_keyword LIKE :pattern ESCAPE '\'
           OR comic_author LIKE :pattern ESCAPE '\'
        ORDER BY CASE
            WHEN comic_title LIKE :pattern ESCAPE '\' THEN 0
            WHEN comic_description LIKE :pattern ESCAPE '\' THEN 1
            WHEN comic_keyword LIKE :pattern ESCAPE '\' THEN 2
            ELSE 3 END,
            comic_updateTime DESC, id DESC
        """
    )
    suspend fun search(pattern: String): List<SearchComicEntry>

    @Query("SELECT query FROM search_history ORDER BY updatedAt DESC, query")
    fun searchHistory(): Flow<List<String>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveSearchHistory(entry: SearchHistoryEntry)

    @Query(
        "DELETE FROM search_history WHERE query NOT IN " +
            "(SELECT query FROM search_history ORDER BY updatedAt DESC, query LIMIT 30)"
    )
    suspend fun trimSearchHistory()

    @Query("DELETE FROM search_history")
    suspend fun clearSearchHistory()
}

@Database(
    entities = [LibraryEntry::class, SearchComicEntry::class, SearchMetadata::class,
        SearchHistoryEntry::class, ChapterCacheEntry::class],
    version = 1,
    exportSchema = true,
)
internal abstract class ComicDatabase : RoomDatabase() {
    abstract fun comics(): ComicDao
}
