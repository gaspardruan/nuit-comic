package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.data.StoredComic
import java.text.DateFormat
import java.text.NumberFormat
import java.util.Date

@Composable
internal fun ComicDetailScreen(
    comic: Comic,
    model: AppViewModel,
    storedComic: StoredComic?,
    onRead: (Comic, List<Chapter>, Int, Int) -> Unit,
    onComic: (Comic) -> Unit,
    modifier: Modifier,
) {
    val chapterState by model.chapters.collectAsStateWithLifecycle()
    val recommendations by model.detailRecommendations.collectAsStateWithLifecycle()
    val chapters = chapterState.value.orEmpty()
    val recommendedComics = recommendations.value.orEmpty()
    val columns = (LocalConfiguration.current.screenWidthDp / 150).coerceIn(3, 6)
    var showDescription by rememberSaveable(comic.id) { mutableStateOf(false) }
    var showChapters by rememberSaveable(comic.id) { mutableStateOf(false) }
    var descriptionOverflows by remember(comic.description) { mutableStateOf(false) }
    val hasRead = storedComic != null && storedComic.lastReadChapterIndex >= 0
    val savedChapterIndex = (storedComic?.lastReadChapterIndex ?: 0).coerceIn(0, chapters.lastIndex.coerceAtLeast(0))
    val firstReadableChapter = chapters.indexOfFirst { chapter -> chapter.images.any(String::isNotBlank) }
    val canRead = firstReadableChapter >= 0
    val chapterIndex = if (chapters.getOrNull(savedChapterIndex)?.images?.any(String::isNotBlank) == true) {
        savedChapterIndex
    } else {
        firstReadableChapter.coerceAtLeast(0)
    }
    val read: (Int, Int) -> Unit = { chapter, page ->
        if (chapters.getOrNull(chapter)?.images?.any(String::isNotBlank) == true) {
            showChapters = false
            onRead(comic, chapters, chapter, page)
        }
    }

    LazyColumn(modifier.fillMaxSize()) {
        item(key = "summary") {
            Column(
                Modifier.fillMaxWidth().padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                ComicCover(comic, Modifier.fillMaxWidth().aspectRatio(15f / 8f), preferCover = true)
                Text(comic.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
                if (comic.author.isNotBlank()) Text(comic.author, color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.bodyMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    StarRating(comic.score / 2)
                    Text(NumberFormat.getNumberInstance().format(comic.score), style = MaterialTheme.typography.bodySmall)
                    Text(stringResource(R.string.detail_views, NumberFormat.getIntegerInstance().format(comic.view)), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Text(comic.keyword.split(',').filter(String::isNotBlank).joinToString(" · "), textAlign = TextAlign.Center, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Row(Modifier.fillMaxWidth().padding(top = 6.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    val collected = storedComic?.isCollected == true
                    OutlinedButton(
                        onClick = { model.setCollected(comic, !collected, chapters.size.takeIf { it > 0 } ?: storedComic?.chapterCount ?: 0) },
                        modifier = Modifier.weight(1f),
                    ) {
                        Icon(if (collected) Icons.Default.Bookmark else Icons.Default.BookmarkBorder, null, Modifier.size(18.dp))
                        Text(stringResource(if (collected) R.string.detail_uncollect else R.string.detail_collect), Modifier.padding(start = 6.dp))
                    }
                    Button(
                        onClick = {
                            val page = if (hasRead && chapterIndex == savedChapterIndex) storedComic?.lastReadPageIndex ?: 0 else 0
                            read(chapterIndex, page)
                        },
                        enabled = canRead,
                        modifier = Modifier.weight(1f),
                    ) {
                        Text(if (hasRead) stringResource(R.string.detail_continue, chapterIndex + 1) else stringResource(R.string.detail_start))
                    }
                }
                ChapterLoadStatus(chapterState, model::reloadChapters)
            }
        }
        item(key = "description") {
            Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
                Text(
                    comic.description.ifBlank { stringResource(R.string.detail_no_description) },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                    onTextLayout = { descriptionOverflows = it.hasVisualOverflow },
                )
                if (descriptionOverflows) {
                    TextButton(onClick = { showDescription = true }, modifier = Modifier.align(Alignment.End)) {
                        Text(stringResource(R.string.detail_more))
                    }
                }
            }
        }
        item(key = "directory") {
            Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
                Row(
                    Modifier.fillMaxWidth().clickable(role = Role.Button) { showChapters = true }.padding(vertical = 18.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Text(stringResource(R.string.detail_directory), style = MaterialTheme.typography.titleLarge)
                    val updateDate = if (comic.updateTime > 0) DateFormat.getDateInstance().format(Date(comic.updateTime)) else ""
                    val summary = when {
                        chapters.isNotEmpty() && comic.isOver -> stringResource(R.string.detail_completed, chapters.size)
                        chapters.isNotEmpty() -> stringResource(R.string.detail_updating, chapters.size, updateDate)
                        chapterState.loading -> stringResource(R.string.common_loading)
                        chapterState.error != null -> stringResource(R.string.common_load_failed)
                        else -> stringResource(R.string.detail_no_chapters)
                    }
                    Text(summary, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.End, modifier = Modifier.weight(1f))
                    Icon(Icons.Default.ChevronRight, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                HorizontalDivider()
            }
        }
        item(key = "recommendations-heading") {
            Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 8.dp, top = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.section_random), Modifier.weight(1f), style = MaterialTheme.typography.titleLarge)
                IconButton(onClick = model::refreshDetailRecommendations, enabled = !recommendations.loading) {
                    Icon(Icons.Default.Refresh, stringResource(R.string.common_refresh))
                }
            }
        }
        if (recommendations.loading && recommendedComics.isEmpty()) item { LoadingState(Modifier.height(110.dp)) }
        if (recommendations.error != null) item { ErrorState(recommendations.error, model::refreshDetailRecommendations) }
        if (!recommendations.loading && recommendations.error == null && recommendedComics.isEmpty()) {
            item { Text(stringResource(R.string.common_empty), Modifier.padding(24.dp), color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        comicGrid(recommendedComics, "detail-recommendations", columns, onComic)
        item { Box(Modifier.height(24.dp)) }
    }

    if (showDescription) FullDescriptionSheet(comic, onDismiss = { showDescription = false })
    if (showChapters) {
        ChapterDirectorySheet(
            comic = comic,
            chapterState = chapterState,
            focusedChapterIndex = savedChapterIndex,
            hasRead = hasRead,
            onRetry = model::reloadChapters,
            onRead = { read(it, 0) },
            onDismiss = { showChapters = false },
        )
    }
}

@Composable
internal fun ChapterLoadStatus(state: LoadState<List<Chapter>>, onRetry: () -> Unit) {
    val chapters = state.value.orEmpty()
    when {
        state.loading -> Row(
            Modifier.fillMaxWidth().padding(vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
            Text(stringResource(R.string.common_loading), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        state.error != null -> ErrorState(state.error, onRetry)
        chapters.none { chapter -> chapter.images.any(String::isNotBlank) } -> Column(
            Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                stringResource(if (chapters.isEmpty()) R.string.detail_no_chapters else R.string.detail_no_readable_pages),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            TextButton(onClick = onRetry) { Text(stringResource(R.string.common_retry)) }
        }
    }
}
