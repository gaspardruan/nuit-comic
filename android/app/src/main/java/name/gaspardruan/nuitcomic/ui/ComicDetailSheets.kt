package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun FullDescriptionSheet(comic: Comic, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(Modifier.fillMaxHeight(0.85f)) {
            DetailSheetHeader(comic.title, onDismiss)
            HorizontalDivider()
            LazyColumn(Modifier.weight(1f)) {
                item { Text(comic.description, Modifier.padding(20.dp), style = MaterialTheme.typography.bodyLarge) }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ChapterDirectorySheet(
    comic: Comic,
    chapterState: LoadState<List<Chapter>>,
    focusedChapterIndex: Int,
    hasRead: Boolean,
    onRetry: () -> Unit,
    onRead: (Int) -> Unit,
    onDismiss: () -> Unit,
) {
    val chapters = chapterState.value.orEmpty()
    var reversed by rememberSaveable(comic.id) { mutableStateOf(false) }
    val indices = if (reversed) chapters.indices.reversed().toList() else chapters.indices.toList()
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(Modifier.fillMaxHeight(0.85f)) {
            DetailSheetHeader(comic.title, onDismiss)
            Row(Modifier.fillMaxWidth().padding(start = 20.dp, end = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(stringResource(R.string.detail_chapters), style = MaterialTheme.typography.titleMedium)
                    if (chapters.isNotEmpty()) {
                        Text(
                            stringResource(R.string.shelf_progress, focusedChapterIndex + 1, chapters.size),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                IconButton(onClick = { reversed = !reversed }, enabled = chapters.isNotEmpty()) {
                    Icon(
                        Icons.Default.SwapVert,
                        stringResource(if (reversed) R.string.detail_ascending else R.string.detail_descending),
                        tint = if (reversed) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                IconButton(
                    onClick = {
                        scope.launch {
                            val position = indices.indexOf(focusedChapterIndex)
                            if (position >= 0) listState.animateScrollToItem(position)
                        }
                    },
                    enabled = chapters.isNotEmpty(),
                ) {
                    Icon(Icons.Default.MyLocation, stringResource(R.string.detail_locate))
                }
            }
            ChapterLoadStatus(chapterState, onRetry)
            HorizontalDivider()
            LazyColumn(Modifier.weight(1f), state = listState) {
                items(indices, key = { chapters[it].id }) { index ->
                    val chapter = chapters[index]
                    val readable = chapter.images.any(String::isNotBlank)
                    val focused = hasRead && index == focusedChapterIndex
                    Row(
                        Modifier.fillMaxWidth().clickable(enabled = readable, role = Role.Button) { onRead(index) }
                            .padding(horizontal = 20.dp, vertical = 17.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        if (focused) Icon(Icons.Default.MenuBook, null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.primary)
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                chapter.title,
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = if (focused) FontWeight.SemiBold else FontWeight.Normal,
                                color = when {
                                    !readable -> MaterialTheme.colorScheme.onSurfaceVariant
                                    focused -> MaterialTheme.colorScheme.primary
                                    else -> MaterialTheme.colorScheme.onSurface
                                },
                            )
                            if (!readable) Text(stringResource(R.string.detail_no_readable_pages), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun DetailSheetHeader(title: String, onDismiss: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(start = 20.dp, end = 8.dp, bottom = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, Modifier.weight(1f), style = MaterialTheme.typography.titleLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
        IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, stringResource(R.string.detail_close)) }
    }
}
