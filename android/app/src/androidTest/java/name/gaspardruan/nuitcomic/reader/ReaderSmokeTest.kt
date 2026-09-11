package name.gaspardruan.nuitcomic.reader

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import androidx.activity.ComponentActivity
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performSemanticsAction
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.test.core.app.ApplicationProvider
import java.io.File
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.runBlocking
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.ReadingSession
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.readerPreferences
import name.gaspardruan.nuitcomic.ui.NuitComicTheme
import okhttp3.OkHttpClient
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class ReaderSmokeTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()

    @Test fun chapterJumpsAndModeChangesKeepTheSelectedPage() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        runBlocking { context.readerPreferences.edit { it[booleanPreferencesKey("horizontal")] = false } }
        val images = ReaderImages(context, OkHttpClient())
        val urls = cachedPages(context, count = 4, tallFirstPage = true)
        val chapters = listOf(Chapter(1, "First", urls.take(3)), Chapter(2, "Empty", emptyList()),
            Chapter(3, "Last", urls.takeLast(1)))
        val session = ReadingSession(comic = Comic(8, "Reader test"), navigator = ReaderNavigator(chapters), initialIndex = 0)
        val position = AtomicInteger(-1)
        compose.setContent { NuitComicTheme { ReaderScreen(session, images, position::set, {}) } }
        compose.waitUntil(5_000) { position.get() == 0 }
        compose.onNodeWithContentDescription(context.getString(R.string.reader_chapters)).performClick()
        compose.onNodeWithText("Last").performClick()
        compose.waitUntil(5_000) { position.get() == 3 }
        compose.onNodeWithContentDescription(context.getString(R.string.reader_horizontal)).performClick()
        compose.waitForIdle()
        assertEquals(3, position.get())
        compose.onNodeWithContentDescription(context.getString(R.string.reader_chapters)).performClick()
        compose.onNodeWithText("First").performClick()
        compose.waitUntil(5_000) { position.get() == 0 }
        compose.onNodeWithContentDescription(context.getString(R.string.reader_vertical)).performClick()
        compose.waitForIdle()
        assertEquals(0, position.get())
    }

    @Test fun sliderTracksOnlyTheCurrentChapterAndDiscardsStaleChanges() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        runBlocking { context.readerPreferences.edit { it[booleanPreferencesKey("horizontal")] = false } }
        val images = ReaderImages(context, OkHttpClient())
        val urls = cachedPages(context, count = 6)
        val chapters = listOf(
            Chapter(1, "First", urls.take(3)),
            Chapter(2, "Empty", emptyList()),
            Chapter(3, "Second", urls.subList(3, 5)),
            Chapter(4, "Single", urls.takeLast(1)),
        )
        val session = ReadingSession(comic = Comic(9, "Chapter slider test"),
            navigator = ReaderNavigator(chapters), initialIndex = 0)
        val position = AtomicInteger(-1)
        compose.setContent { NuitComicTheme { ReaderScreen(session, images, position::set, {}) } }
        compose.waitUntil(5_000) { position.get() == 0 }
        assertSlider(page = 0, lastPage = 2)
        slider().performSemanticsAction(SemanticsActions.SetProgress) { it(2f) }
        compose.waitUntil(5_000) { position.get() == 2 }
        assertSlider(page = 2, lastPage = 2)
        compose.onNodeWithText(context.getString(R.string.reader_position, 3, 3)).assertExists()
        val previousChapterChange = slider().fetchSemanticsNode().config[SemanticsActions.SetProgress].action!!

        jumpToChapter(context, "Second")
        compose.waitUntil(5_000) { position.get() == 3 }
        assertSlider(page = 0, lastPage = 1)
        // A late callback from the previous chapter must not overwrite the new reading position.
        compose.runOnIdle { previousChapterChange(1f) }
        compose.waitForIdle()
        assertEquals(3, position.get())
        slider().performSemanticsAction(SemanticsActions.SetProgress) { it(1f) }
        compose.waitUntil(5_000) { position.get() == 4 }
        assertSlider(page = 1, lastPage = 1)
        compose.onNodeWithText(context.getString(R.string.reader_position, 2, 2)).assertExists()

        jumpToChapter(context, "Single")
        compose.waitUntil(5_000) { position.get() == 5 }
        slider().assertDoesNotExist()
        compose.onNodeWithText(context.getString(R.string.reader_position, 1, 1)).assertExists()

        jumpToChapter(context, "First")
        compose.waitUntil(5_000) { position.get() == 0 }
        assertSlider(page = 0, lastPage = 2)
        slider().performSemanticsAction(SemanticsActions.SetProgress) { it(1f) }
        compose.waitUntil(5_000) { position.get() == 1 }
        assertSlider(page = 1, lastPage = 2)
    }

    private fun slider() = compose.onNode(SemanticsMatcher.keyIsDefined(SemanticsActions.SetProgress))

    private fun assertSlider(page: Int, lastPage: Int) {
        assertEquals(ProgressBarRangeInfo(page.toFloat(), 0f..lastPage.toFloat(), steps = lastPage - 1),
            slider().fetchSemanticsNode().config[SemanticsProperties.ProgressBarRangeInfo])
    }

    private fun jumpToChapter(context: Context, title: String) {
        compose.onNodeWithContentDescription(context.getString(R.string.reader_chapters)).performClick()
        compose.onNodeWithText(title).performClick()
    }

    private fun cachedPages(context: Context, count: Int, tallFirstPage: Boolean = false): List<String> {
        val urls = List(count) { "https://example.invalid/${UUID.randomUUID()}.png" }
        val directory = File(context.cacheDir, "reader-pages").apply { mkdirs() }
        urls.forEachIndexed { index, url ->
            val file = File(directory, MessageDigest.getInstance("SHA-256").digest(url.toByteArray())
                .joinToString("") { "%02x".format(it) })
            val bitmap = Bitmap.createBitmap(400, if (tallFirstPage && index == 0) 6000 else 600,
                Bitmap.Config.ARGB_8888)
            bitmap.eraseColor(if (index % 2 == 0) Color.BLUE else Color.GREEN)
            file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            bitmap.recycle()
        }
        return urls
    }
}
