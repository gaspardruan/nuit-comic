package name.gaspardruan.nuitcomic

import android.app.Application
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import java.util.UUID
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.reader.ReaderNavigator
import name.gaspardruan.nuitcomic.reader.ReaderScreen
import name.gaspardruan.nuitcomic.ui.NuitComicApp
import name.gaspardruan.nuitcomic.ui.NuitComicTheme

class MainActivity : ComponentActivity() {
    private val model: ReadingViewModel by viewModels()
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val app = application as NuitComicApplication
        setContent {
            NuitComicTheme {
                Surface(Modifier.fillMaxSize()) {
                    val reading by model.reading.collectAsStateWithLifecycle()
                    Box {
                        NuitComicApp(app.repository, readerActive = reading != null, onRead = model::open)
                        reading?.let { session ->
                            ReaderScreen(session, app.readerImages,
                                { index -> model.positionChanged(session.id, index) }, model::close)
                        }
                    }
                }
            }
        }
    }
}

data class ReadingSession(
    val id: String = UUID.randomUUID().toString(),
    val comic: Comic,
    val navigator: ReaderNavigator,
    val initialIndex: Int,
)

class ReadingViewModel(application: Application, private val saved: SavedStateHandle) : AndroidViewModel(application) {
    private val app = application as NuitComicApplication
    private val mutableReading = MutableStateFlow<ReadingSession?>(null)
    val reading = mutableReading.asStateFlow()

    init {
        val comicId = saved.get<Int>("readingComic")
        if (comicId != null) viewModelScope.launch {
            // Only an id and position enter saved instance state; large chapter lists stay out of Bundles.
            val stored = app.repository.library.first().firstOrNull { it.comic.id == comicId }
            if (stored != null) try {
                val chapters = app.repository.chapters(comicId)
                if (reading.value == null && saved.get<Int>("readingComic") == comicId)
                    open(stored.comic, chapters, saved["readingChapter"] ?: stored.lastReadChapterIndex,
                    saved["readingPage"] ?: stored.lastReadPageIndex)
            } catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { /* The library remains available for an explicit retry. */ }
        }
    }

    fun open(comic: Comic, chapters: List<Chapter>, chapter: Int, page: Int) {
        val navigator = ReaderNavigator(chapters)
        if (navigator.pages.isEmpty()) return
        val position = navigator.position(chapter, page)
        val session = ReadingSession(comic = comic, navigator = navigator, initialIndex = position)
        mutableReading.value = session
        saved["readingComic"] = comic.id
        positionChanged(session.id, position)
    }

    fun positionChanged(sessionID: String, index: Int) {
        val session = reading.value?.takeIf { it.id == sessionID } ?: return
        val page = session.navigator.pageAt(index) ?: return
        saved["readingChapter"] = page.chapterIndex
        saved["readingPage"] = page.pageIndex
        app.saveReading(ReadingSave(session.comic, page.chapterIndex, page.pageIndex, session.navigator.chapters.size))
    }

    fun close() {
        mutableReading.value = null
        saved.remove<Int>("readingComic")
    }
}
