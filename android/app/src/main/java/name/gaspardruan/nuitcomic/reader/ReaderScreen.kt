package name.gaspardruan.nuitcomic.reader

import android.app.Activity
import android.view.WindowManager
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlin.math.roundToInt
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import name.gaspardruan.nuitcomic.NuitComicApplication
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.ReadingSession
import name.gaspardruan.nuitcomic.readerPreferences

private val horizontalKey = booleanPreferencesKey("horizontal")

@Composable
fun ReaderScreen(
    session: ReadingSession,
    images: ReaderImages,
    onPosition: (Int) -> Unit,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as NuitComicApplication
    val preferences = remember { context.readerPreferences.data.map { it[horizontalKey] ?: false } }
    val horizontal by preferences.collectAsStateWithLifecycle(false)
    val scope = rememberCoroutineScope()
    var position by rememberSaveable(session.id) { mutableIntStateOf(session.initialIndex) }
    var generation by rememberSaveable(session.id) { mutableIntStateOf(0) }
    var toolbar by rememberSaveable(session.id) { mutableStateOf(true) }
    var chapterList by remember { mutableStateOf(false) }
    val metadata = remember(session.id) { mutableStateMapOf<String, PageInfo>() }
    val errors = remember(session.id) { mutableStateMapOf<String, Boolean>() }
    val pages = session.navigator.pages
    val pageIndices = remember(session.id) { pages.mapIndexed { index, page -> page.key to index }.toMap() }
    val current = pages[position.coerceIn(pages.indices)]
    val currentChapter = session.navigator.chapters[current.chapterIndex]
    val saveError by app.saveError.collectAsStateWithLifecycle()

    BackHandler { onClose() }
    DisposableEffect(context) {
        val activity = context as? Activity
        val window = activity?.window
        val controller = window?.let { WindowCompat.getInsetsController(it, it.decorView) }
        window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        controller?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        controller?.hide(WindowInsetsCompat.Type.systemBars())
        onDispose {
            window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            controller?.show(WindowInsetsCompat.Type.systemBars())
        }
    }
    LaunchedEffect(toolbar, chapterList) {
        if (toolbar && !chapterList) { delay(3500); toolbar = false }
    }
    LaunchedEffect(session.id, position) { onPosition(position) }
    fun jump(index: Int) {
        position = index.coerceIn(pages.indices)
        generation++
        toolbar = true
    }
    BoxWithConstraints(Modifier.fillMaxSize().background(Color.Black)
        .pointerInput(Unit) { detectTapGestures { toolbar = !toolbar } }) {
        val width = with(LocalDensity.current) { maxWidth.roundToPx() }.coerceAtLeast(1)
        val viewportHeight = with(LocalDensity.current) { maxHeight.roundToPx() }.coerceAtLeast(1)
        var visiblePieces by remember(session.id, generation, horizontal, width) {
            mutableStateOf(emptyList<PagePiece>())
        }
        val viewport = visiblePieces.takeIf { it.firstOrNull()?.page == position }
            ?: listOf(PagePiece(position, 0, "${current.key}:0"))
        val lastPrefetchPage = (viewport.last().page + 6).coerceAtMost(pages.lastIndex)
        // Retain overlapping downloads, including six pages beyond the last visible page.
        pages.subList(position, lastPrefetchPage + 1).map { it.url }.distinct().forEach { url ->
            key(session.id, url) {
                LaunchedEffect(images) {
                    if (metadata[url] == null) try {
                        metadata[url] = images.info(url)
                        errors.remove(url)
                    } catch (cancelled: CancellationException) { throw cancelled }
                    catch (_: Exception) { errors[url] = true }
                }
            }
        }
        nearbyReaderTiles(pages, metadata, viewport, width, viewportHeight, horizontal,
            images.prefetchByteBudget).forEach { piece ->
            val url = pages[piece.page].url
            val info = metadata.getValue(url)
            key(session.id, url, piece.tile, width) {
                LaunchedEffect(images, info) {
                    try { images.prefetchTile(url, info, piece.tile, width) }
                    catch (cancelled: CancellationException) { throw cancelled }
                    catch (_: Exception) { /* Visible loading presents errors and offers retry. */ }
                }
            }
        }
        val pieces by remember(session.id, width) {
            derivedStateOf {
                buildList {
                    pages.forEachIndexed { index, page ->
                        repeat(metadata[page.url]?.tileCount(width) ?: 1) { tile ->
                            add(PagePiece(index, tile, "${page.key}:$tile"))
                        }
                    }
                }
            }
        }
        key(session.id, generation, horizontal) {
            if (horizontal) {
                val pager = rememberPagerState(initialPage = position, pageCount = { pages.size })
                LaunchedEffect(pager) {
                    snapshotFlow { pager.settledPage }.distinctUntilChanged().collect { position = it }
                }
                HorizontalPager(pager, modifier = Modifier.fillMaxSize(), key = { pages[it].key }) { index ->
                    val page = pages[index]
                    val info = metadata[page.url]
                    val scroll = rememberLazyListState()
                    if (index == pager.settledPage) LaunchedEffect(scroll, width) {
                        snapshotFlow {
                            scroll.layoutInfo.visibleItemsInfo.filter {
                                it.offset + it.size > scroll.layoutInfo.viewportStartOffset &&
                                    it.offset < scroll.layoutInfo.viewportEndOffset
                            }.map { PagePiece(index, it.index, "${page.key}:${it.index}") }
                        }.distinctUntilChanged().collect { visiblePieces = it }
                    }
                    LazyColumn(Modifier.fillMaxSize(), state = scroll,
                        verticalArrangement = Arrangement.Center) {
                        items(info?.tileCount(width) ?: 1) { tile ->
                            PageTile(page, info, tile, width, images, errors[page.url] == true) {
                                scope.launch {
                                    errors.remove(page.url)
                                    try { metadata[page.url] = images.info(page.url) }
                                    catch (cancelled: CancellationException) { throw cancelled }
                                    catch (_: Exception) { errors[page.url] = true }
                                }
                            }
                        }
                    }
                }
            } else {
                val initialPiece = remember { pieces.indexOfFirst { it.page == position }.coerceAtLeast(0) }
                val list = rememberLazyListState(initialFirstVisibleItemIndex = initialPiece)
                LaunchedEffect(list, width) {
                    // Metadata can insert strips before the viewport. Track stable page keys, not old list indices.
                    snapshotFlow {
                        list.layoutInfo.visibleItemsInfo.filter {
                            it.offset + it.size > list.layoutInfo.viewportStartOffset &&
                                it.offset < list.layoutInfo.viewportEndOffset
                        }.mapNotNull { item ->
                            val key = item.key as? String ?: return@mapNotNull null
                            val page = pageIndices[key.substringBeforeLast(':')] ?: return@mapNotNull null
                            val tile = key.substringAfterLast(':').toIntOrNull() ?: return@mapNotNull null
                            PagePiece(page, tile, key)
                        }
                    }.distinctUntilChanged().collect { visible ->
                        if (visible.isNotEmpty()) {
                            visiblePieces = visible
                            position = visible.first().page
                        }
                    }
                }
                LazyColumn(Modifier.fillMaxSize(), state = list) {
                    items(pieces, key = { it.key }) { piece ->
                        val page = pages[piece.page]
                        PageTile(page, metadata[page.url], piece.tile, width, images, errors[page.url] == true) {
                            scope.launch {
                                errors.remove(page.url)
                                try { metadata[page.url] = images.info(page.url) }
                                catch (cancelled: CancellationException) { throw cancelled }
                                catch (_: Exception) { errors[page.url] = true }
                            }
                        }
                    }
                    item("end") {
                        // A full-height end panel lets even a short final page align at the top after a chapter jump.
                        Box(Modifier.fillMaxWidth().height(maxHeight), contentAlignment = Alignment.TopCenter) {
                            Text(stringResource(R.string.reader_end), color = Color.Gray,
                                modifier = Modifier.padding(32.dp))
                        }
                    }
                }
            }
        }
        if (toolbar) {
            Row(Modifier.align(Alignment.TopCenter).fillMaxWidth().background(Color.Black.copy(alpha = 0.8f))
                .statusBarsPadding().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onClose) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(R.string.reader_close), tint = Color.White)
                }
                Column(Modifier.weight(1f)) {
                    Text(session.comic.title, color = Color.White, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(currentChapter.title, color = Color.LightGray,
                        style = MaterialTheme.typography.bodySmall, maxLines = 1)
                }
            }
            Column(Modifier.align(Alignment.BottomCenter).fillMaxWidth()
                .background(Color.Black.copy(alpha = 0.8f)).navigationBarsPadding().padding(12.dp)) {
                if (saveError != null) {
                    TextButton(onClick = app::retrySave) {
                        Text(stringResource(R.string.reader_save_failed), color = Color(0xFFFFB4AB))
                    }
                }
                key(session.id, current.chapterIndex) {
                    var slider by remember(current.pageIndex) { mutableFloatStateOf(current.pageIndex.toFloat()) }
                    if (currentChapter.images.size > 1) Slider(value = slider, onValueChange = { slider = it },
                        onValueChangeFinished = {
                            // Ignore a gesture that ended after navigation changed the visible chapter.
                            if (pages[position].chapterIndex == current.chapterIndex) {
                                jump(session.navigator.position(current.chapterIndex, slider.roundToInt()))
                            }
                        }, valueRange = 0f..currentChapter.images.lastIndex.toFloat(),
                        steps = currentChapter.images.size - 2)
                }
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween) {
                    IconButton(onClick = { scope.launch {
                        context.readerPreferences.edit { it[horizontalKey] = !horizontal }
                    } }) {
                        Icon(if (horizontal) Icons.Default.SwapVert else Icons.Default.SwapHoriz,
                            stringResource(if (horizontal) R.string.reader_vertical else R.string.reader_horizontal), tint = Color.White)
                    }
                    Text(stringResource(R.string.reader_position, current.pageIndex + 1,
                        currentChapter.images.size), color = Color.White)
                    IconButton(onClick = { chapterList = true }) {
                        Icon(Icons.AutoMirrored.Filled.List, stringResource(R.string.reader_chapters), tint = Color.White)
                    }
                }
            }
        }
    }
    if (chapterList) Dialog(onDismissRequest = { chapterList = false }) {
        Surface(shape = MaterialTheme.shapes.large, modifier = Modifier.fillMaxWidth().fillMaxHeight(0.8f)) {
            Column(Modifier.padding(16.dp)) {
                Text(stringResource(R.string.reader_chapters), style = MaterialTheme.typography.titleLarge,
                    modifier = Modifier.padding(bottom = 12.dp))
                LazyColumn(state = rememberLazyListState(initialFirstVisibleItemIndex = current.chapterIndex)) {
                    items(session.navigator.chapters.size) { index ->
                        val chapter = session.navigator.chapters[index]
                        Text(chapter.title, color = if (index == current.chapterIndex) MaterialTheme.colorScheme.primary
                            else if (chapter.images.isEmpty()) MaterialTheme.colorScheme.outline else MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.fillMaxWidth().clickable(enabled = chapter.images.isNotEmpty()) {
                                jump(session.navigator.position(index)); chapterList = false
                            }.padding(vertical = 14.dp))
                    }
                }
            }
        }
    }
}

@Composable
internal fun PageTile(page: ReaderPage, info: PageInfo?, tile: Int, width: Int, images: ReaderImages,
                     metadataFailed: Boolean, retryMetadata: () -> Unit) {
    var retry by remember(page.url) { mutableIntStateOf(0) }
    var failed by remember(page.url, info, tile, width, retry) { mutableStateOf(false) }
    var bitmap by remember(images, page.url, tile, width) {
        mutableStateOf(images.cachedTile(page.url, tile, width))
    }
    LaunchedEffect(images, page.url, info, tile, width, retry) {
        if (bitmap == null) bitmap = images.cachedTile(page.url, tile, width)
        if (bitmap == null && info != null) {
            try { bitmap = images.tile(page.url, info, tile, width) }
            catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { failed = true }
        }
    }
    val loaded = bitmap
    val heightPixels = when {
        info != null -> info.tileHeight(tile, width).toFloat() * width / info.width
        loaded != null -> loaded.height.toFloat() * width / loaded.width
        else -> width / 0.618f
    }
    val height = with(LocalDensity.current) { heightPixels.toDp() }
    Box(Modifier.fillMaxWidth().height(height), contentAlignment = Alignment.Center) {
        if (loaded != null) Image(loaded.asImageBitmap(), contentDescription = null,
            contentScale = ContentScale.FillBounds, modifier = Modifier.fillMaxSize())
        else if (failed || metadataFailed) TextButton(onClick = { retry++; retryMetadata() }) {
            Text(stringResource(R.string.reader_retry), color = Color.White)
        } else CircularProgressIndicator(Modifier.size(28.dp), color = Color.LightGray, strokeWidth = 2.dp)
    }
}
