package name.gaspardruan.nuitcomic.reader

import androidx.lifecycle.SavedStateHandle
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import name.gaspardruan.nuitcomic.NuitComicApplication
import name.gaspardruan.nuitcomic.ReadingViewModel
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ReadingSessionTest {
    @Test fun reopeningSamePageRestoresDeletedUncollectedHistory() = runBlocking {
        reopeningRestoresHistory(collected = false)
    }

    @Test fun reopeningSamePageRestoresDeletedCollectedHistory() = runBlocking {
        reopeningRestoresHistory(collected = true)
    }

    @Test fun callbacksFromAnOldReadingSessionCannotOverwriteTheNewPosition() {
        val app = ApplicationProvider.getApplicationContext<NuitComicApplication>()
        val saved = SavedStateHandle()
        val model = ReadingViewModel(app, saved)
        val chapters = listOf(Chapter(1, "First", listOf("a", "b", "c")))
        model.open(Comic(-101, "Session test"), chapters, 0, 0)
        val oldID = model.reading.value!!.id
        model.open(Comic(-102, "Next session"), chapters, 0, 2)
        model.positionChanged(oldID, 0)
        assertEquals(2, saved.get<Int>("readingPage"))
        model.close()
        model.positionChanged(oldID, 1)
        assertNull(saved.get<Int>("readingComic"))
    }

    private suspend fun reopeningRestoresHistory(collected: Boolean) {
        val app = ApplicationProvider.getApplicationContext<NuitComicApplication>()
        val repository = app.repository
        val comic = Comic(if (collected) -201 else -202, "Reopened reading history")
        val ids = setOf(comic.id)
        val chapters = listOf(Chapter(1, "First", listOf("page-one", "page-two")))
        val model = ReadingViewModel(app, SavedStateHandle())
        repository.removeCollections(ids)
        repository.removeHistory(ids)
        try {
            if (collected) repository.setCollected(comic, true, chapters.size)
            model.open(comic, chapters, 0, 0)
            withTimeout(5_000) {
                repository.library.first { entries ->
                    entries.any { it.comic.id == comic.id && it.lastReadChapterIndex == 0 && it.lastReadPageIndex == 0 }
                }
            }
            model.close()

            repository.removeHistory(ids)
            val cleared = withTimeout(5_000) {
                repository.library.first { entries ->
                    entries.none { it.comic.id == comic.id && it.lastReadChapterIndex >= 0 }
                }
            }.firstOrNull { it.comic.id == comic.id }
            if (collected) {
                assertEquals(true, cleared?.isCollected)
                assertEquals(-1, cleared?.lastReadChapterIndex)
            } else {
                assertNull(cleared)
            }

            // A new session must persist its first page even when it matches the last session.
            model.open(comic, chapters, 0, 0)
            val restored = withTimeout(5_000) {
                repository.library.first { entries ->
                    entries.any { it.comic.id == comic.id && it.lastReadChapterIndex == 0 && it.lastReadPageIndex == 0 }
                }
            }.single { it.comic.id == comic.id }
            assertEquals(collected, restored.isCollected)
            assertEquals(chapters.size, restored.chapterCount)
        } finally {
            model.close()
            repository.removeCollections(ids)
            repository.removeHistory(ids)
        }
    }
}
