package name.gaspardruan.nuitcomic.ui

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onLast
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isEnabled
import androidx.compose.ui.text.TextLayoutResult
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.viewmodel.compose.LocalViewModelStoreOwner
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import java.util.UUID
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import name.gaspardruan.nuitcomic.R
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
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test

/** Deterministic browsing checks use Room and an in-process source, never production servers. */
class BrowsingSmokeTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val databaseName = "ui-smoke-${UUID.randomUUID()}.db"
    private var comic = Comic(42, "Moon Journey", description = "A quiet journey under the moon", author = "Night")
    private val chapters = listOf(
        Chapter(7, "Chapter one", listOf("https://example.invalid/page-one.jpg")),
        Chapter(8, "Chapter two", listOf("https://example.invalid/page-two.jpg")),
        Chapter(9, "Chapter three", listOf("https://example.invalid/page-three.jpg")),
    )
    private val recommendation = Comic(84, "Dawn Adventures", description = "A new day")
    private val recommendationChapters = listOf(Chapter(80, "Dawn chapter", listOf("https://example.invalid/dawn.jpg")))
    private var recommendations = emptyList<Comic>()
    private lateinit var repository: ComicRepository
    private val visible = mutableStateOf(true)
    private val owner = mutableStateOf(newOwner())
    private var indexGate: CompletableDeferred<Unit>? = null
    private val read = AtomicReference<Pair<Int, Int>?>(null)
    private val readComic = AtomicReference<Comic?>(null)
    private val source = object : ComicSource {
        override suspend fun home() = HomeFeed(mapOf(HomeSection.NEW to listOf(comic)))
        override suspend fun random() = recommendations
        override suspend fun list(section: HomeSection, page: Int) = if (page == 1) listOf(comic) else emptyList()
        override suspend fun chapters(comicID: Int) = if (comicID == comic.id) chapters else recommendationChapters
        override suspend fun allComics(): List<Comic> {
            indexGate?.await()
            return listOf(comic, recommendation)
        }
    }
    private val client = OkHttpClient.Builder().addInterceptor { chain ->
        Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1)
            .code(200).message("OK").body("[]".toResponseBody("application/json".toMediaType())).build()
    }.build()

    @Before fun setUp() {
        context.getSharedPreferences("shelf", Context.MODE_PRIVATE).edit()
            .putBoolean("grid", true).putBoolean("sortByTitle", false).commit()
        repository = openRepository()
    }

    @After fun tearDown() {
        compose.runOnIdle { visible.value = false; owner.value.viewModelStore.clear() }
        repository.close()
        context.deleteDatabase(databaseName)
    }

    @Test fun homeOpensDetailAndPassesChapterPositionToReader() {
        launch()
        openDetail()
        compose.onNodeWithText(text(R.string.detail_start)).performScrollTo().performClick()
        compose.waitUntil(5_000) { read.get() != null }
        assertEquals(0 to 0, read.get())
        compose.onNodeWithContentDescription(text(R.string.common_back)).performClick()
        compose.onNodeWithText(comic.title).assertIsDisplayed()
    }

    @Test fun collectionAndReadingProgressSurviveUiAndDatabaseRecreation() {
        launch()
        openDetail()
        compose.onNodeWithText(text(R.string.detail_collect)).performScrollTo().performClick()
        compose.waitUntil(5_000) { runBlocking { repository.library.first().any { it.isCollected } } }
        runBlocking { repository.recordReading(comic, 0, 0, chapters.size) }
        compose.runOnIdle { visible.value = false; owner.value.viewModelStore.clear() }
        compose.waitForIdle()
        repository.close()
        repository = openRepository()
        compose.runOnIdle { owner.value = newOwner(); visible.value = true }
        compose.onAllNodesWithText(text(R.string.tab_shelf)).onLast().performClick()
        waitForComic()
        compose.onNodeWithText(comic.title).performClick()
        compose.onNodeWithText(text(R.string.detail_uncollect)).performScrollTo().assertIsDisplayed()
        compose.onNodeWithText(context.getString(R.string.detail_continue, 1)).assertIsDisplayed()
        assertTrue(runBlocking { repository.library.first().single().isCollected })
    }

    @Test fun searchWaitsForIndexAndUsesTheSameQueryWhenIndexBecomesReady() {
        indexGate = CompletableDeferred()
        launch()
        compose.onAllNodesWithText(text(R.string.tab_search)).onLast().performClick()
        compose.onNode(hasSetTextAction()).performTextInput("Moon")
        compose.onNodeWithText(text(R.string.search_preparing)).assertIsDisplayed()
        indexGate?.complete(Unit)
        waitForComic()
        compose.onNodeWithText(comic.title).performClick()
        compose.onNodeWithText(text(R.string.detail_start)).performScrollTo().assertIsDisplayed()
        compose.onNodeWithContentDescription(text(R.string.common_back)).performClick()
        compose.onNode(hasSetTextAction()).assertIsDisplayed()
        waitForComic()
        compose.onNodeWithText(comic.title).assertIsDisplayed()
    }

    @Test fun aboutActionOnlyAppearsOnRootSearch() {
        launch()
        waitForComic()
        compose.onNodeWithContentDescription(text(R.string.about_title)).assertDoesNotExist()
        selectTab(R.string.tab_shelf)
        compose.onNodeWithContentDescription(text(R.string.about_title)).assertDoesNotExist()
        compose.onNodeWithContentDescription(text(R.string.shelf_options)).assertIsDisplayed()
        selectTab(R.string.tab_search)
        compose.onNodeWithContentDescription(text(R.string.shelf_options)).assertDoesNotExist()
        compose.onNodeWithContentDescription(text(R.string.about_title)).performClick()
        compose.onNodeWithContentDescription(text(R.string.about_title)).assertDoesNotExist()
        compose.onNodeWithContentDescription(text(R.string.common_back)).performClick()
        compose.onNodeWithContentDescription(text(R.string.about_title)).assertIsDisplayed()
        compose.onNode(hasSetTextAction()).performTextInput("Moon")
        waitForComic()
        compose.onNodeWithText(comic.title).performClick()
        compose.onNodeWithContentDescription(text(R.string.about_title)).assertDoesNotExist()
    }

    @Test fun shelfAppBarOptionsStillChangeLayoutSortAndSelection() {
        runBlocking {
            repository.setCollected(recommendation, true, recommendationChapters.size)
            repository.setCollected(comic, true, chapters.size)
        }
        launch()
        selectTab(R.string.tab_shelf)
        waitForComic()
        compose.onAllNodesWithContentDescription(text(R.string.shelf_options)).assertCountEquals(1)
        val options = compose.onNodeWithContentDescription(text(R.string.shelf_options))
        val collectionTab = compose.onNodeWithText(text(R.string.shelf_collections))
        assertTrue(options.fetchSemanticsNode().boundsInRoot.bottom <= collectionTab.fetchSemanticsNode().boundsInRoot.top)
        compose.onNodeWithText(comic.description).assertDoesNotExist()

        options.performClick()
        compose.onNodeWithText(text(R.string.shelf_list)).performClick()
        compose.onNodeWithText(comic.description).assertIsDisplayed()
        options.performClick()
        compose.onNodeWithText(text(R.string.shelf_sort_title)).performClick()
        assertTrue(
            compose.onNodeWithText(recommendation.title).fetchSemanticsNode().boundsInRoot.top <
                compose.onNodeWithText(comic.title).fetchSemanticsNode().boundsInRoot.top,
        )
        options.performClick()
        compose.onNodeWithText(text(R.string.common_select)).performClick()
        compose.onNodeWithText(comic.title).performClick()
        compose.onNodeWithContentDescription(text(R.string.shelf_selected)).assertIsDisplayed()
        compose.onNodeWithText(context.getString(R.string.shelf_delete_count, 1)).assertIsDisplayed()
        val done = compose.onNodeWithText(text(R.string.common_done))
        assertTrue(done.fetchSemanticsNode().boundsInRoot.bottom <= collectionTab.fetchSemanticsNode().boundsInRoot.top)
        done.performClick()
        compose.onNodeWithContentDescription(text(R.string.shelf_selected)).assertDoesNotExist()

        options.performClick()
        compose.onNodeWithText(text(R.string.common_select)).performClick()
        compose.onNodeWithText(text(R.string.shelf_select_all)).performClick()
        compose.onNodeWithText(context.getString(R.string.shelf_delete_count, 2)).performClick()
        compose.onNodeWithText(text(R.string.shelf_delete_collections)).assertIsDisplayed()
        compose.onNodeWithText(text(R.string.common_cancel)).performClick()
        compose.onNodeWithText(comic.title).assertIsDisplayed()
        compose.onNodeWithText(context.getString(R.string.shelf_delete_count, 2)).performClick()
        compose.onNodeWithText(text(R.string.common_delete)).performClick()
        compose.waitUntil(5_000) { runBlocking { repository.library.first().none { it.isCollected } } }
        compose.onNodeWithText(text(R.string.shelf_empty)).assertIsDisplayed()
        options.assertIsDisplayed()
    }

    @Test fun directoryKeepsChaptersOutOfDetailAndReadsOriginalIndexAfterReversing() {
        launch()
        openDetail()
        scrollDetailTo(text(R.string.section_random))
        chapters.forEach { compose.onNodeWithText(it.title).assertDoesNotExist() }
        scrollDetailTo(text(R.string.detail_directory))
        compose.onNodeWithText(text(R.string.detail_directory)).performClick()
        chapters.forEach { compose.onNodeWithText(it.title).assertIsDisplayed() }
        compose.onNodeWithContentDescription(text(R.string.detail_descending)).performClick()
        assertTrue(
            compose.onNodeWithText(chapters.last().title).fetchSemanticsNode().boundsInRoot.top <
                compose.onNodeWithText(chapters.first().title).fetchSemanticsNode().boundsInRoot.top,
        )
        compose.onNodeWithText(chapters.last().title).performClick()
        compose.waitUntil(5_000) { read.get() != null }
        assertEquals(2 to 0, read.get())
        assertEquals(comic.id, readComic.get()?.id)
        compose.onNodeWithText(chapters.last().title).assertDoesNotExist()
    }

    @Test fun recommendationOpensItsOwnDetailAndDirectoryThenReturnsToOriginal() {
        recommendations = listOf(comic, recommendation)
        launch()
        openDetail()
        scrollDetailTo(recommendation.title)
        compose.onNodeWithText(recommendation.title).performClick()
        waitForReadingAction()
        compose.onAllNodesWithText(recommendation.title).onFirst().assertIsDisplayed()
        scrollDetailTo(text(R.string.detail_directory))
        compose.onNodeWithText(text(R.string.detail_directory)).performClick()
        compose.onNodeWithText(recommendationChapters.single().title).assertIsDisplayed().performClick()
        compose.waitUntil(5_000) { read.get() != null }
        assertEquals(recommendation.id, readComic.get()?.id)
        assertEquals(0 to 0, read.get())
        compose.onNodeWithContentDescription(text(R.string.common_back)).performClick()
        compose.onAllNodesWithText(comic.title).onFirst().assertIsDisplayed()
        scrollDetailTo(text(R.string.detail_directory))
        compose.onNodeWithText(text(R.string.detail_directory)).performClick()
        compose.onNodeWithText(chapters.first().title).assertIsDisplayed()
        compose.onNodeWithText(recommendationChapters.single().title).assertDoesNotExist()
    }

    @Test fun shortDescriptionDoesNotOfferMore() {
        launch()
        openDetail()
        scrollDetailTo(comic.description)
        compose.onNodeWithText(comic.description).assertIsDisplayed()
        assertFalse(textLayout(compose.onNodeWithText(comic.description)).hasVisualOverflow)
        compose.onNodeWithText(text(R.string.detail_more)).assertDoesNotExist()
    }

    @Test fun multilineOverflowOffersCompleteDescriptionEvenWithFewCharacters() {
        comic = comic.copy(description = "Moonrise\nQuiet road\nPaper stars\nNew friends\nDawn")
        launch()
        openDetail()
        scrollDetailTo(comic.description)
        assertTrue(textLayout(compose.onNodeWithText(comic.description)).hasVisualOverflow)
        compose.onNodeWithText(text(R.string.detail_more)).performScrollTo().performClick()
        val fullDescription = compose.onAllNodesWithText(comic.description).onLast()
        fullDescription.assertIsDisplayed()
        val fullLayout = textLayout(fullDescription)
        assertEquals(5, fullLayout.lineCount)
        assertFalse(fullLayout.didOverflowHeight)
        // Semantics can retain the parent's paragraph width for wrap-content Text; inspect actual lines.
        comic.description.lines().forEachIndexed { line, expected ->
            assertFalse(fullLayout.isLineEllipsized(line))
            assertTrue("Line $line fits horizontally", fullLayout.getLineLeft(line) >= 0f &&
                fullLayout.getLineRight(line) <= fullLayout.size.width)
            assertEquals(expected, comic.description.substring(fullLayout.getLineStart(line), fullLayout.getLineEnd(line, visibleEnd = true)))
        }
        assertEquals(comic.description.length, fullLayout.getLineEnd(fullLayout.lineCount - 1, visibleEnd = true))
        compose.onNodeWithContentDescription(text(R.string.detail_close)).performClick()
        compose.waitUntil(5_000) {
            compose.onAllNodesWithContentDescription(text(R.string.detail_close)).fetchSemanticsNodes().isEmpty() &&
                compose.onAllNodesWithText(comic.description).fetchSemanticsNodes().size == 1
        }
        compose.onNodeWithText(text(R.string.detail_more)).assertIsDisplayed()
        assertTrue(textLayout(compose.onNodeWithText(comic.description)).hasVisualOverflow)
    }

    private fun launch() {
        compose.setContent {
            if (visible.value) CompositionLocalProvider(LocalViewModelStoreOwner provides owner.value) {
                NuitComicTheme {
                    NuitComicApp(repository) { openedComic, openedChapters, chapter, page ->
                        assertTrue(openedComic.id == comic.id || openedComic.id == recommendation.id)
                        assertEquals(if (openedComic.id == comic.id) chapters else recommendationChapters, openedChapters)
                        readComic.set(openedComic)
                        read.set(chapter to page)
                    }
                }
            }
        }
    }

    private fun openDetail() {
        waitForComic()
        compose.onAllNodesWithText(comic.title).onFirst().performClick()
        waitForReadingAction()
        compose.waitForIdle()
    }

    private fun waitForReadingAction() = compose.waitUntil(5_000) {
        compose.onAllNodes(hasText(text(R.string.detail_start)) and isEnabled()).fetchSemanticsNodes().isNotEmpty()
    }

    private fun selectTab(label: Int) = compose.onAllNodesWithText(text(label)).onLast().performClick()

    private fun scrollDetailTo(value: String) {
        compose.onNode(hasScrollToIndexAction()).performScrollToNode(hasText(value))
    }

    private fun textLayout(node: SemanticsNodeInteraction): TextLayoutResult {
        val results = mutableListOf<TextLayoutResult>()
        node.performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(results) }
        return results.single()
    }

    private fun waitForComic() = compose.waitUntil(10_000) {
        compose.onAllNodesWithText(comic.title).fetchSemanticsNodes().isNotEmpty()
    }

    private fun openRepository() = ComicRepository(
        Room.databaseBuilder(context, ComicDatabase::class.java, databaseName).build(), source, client,
    )

    private fun text(id: Int) = context.getString(id)
    private fun newOwner() = object : ViewModelStoreOwner { override val viewModelStore = ViewModelStore() }
}
