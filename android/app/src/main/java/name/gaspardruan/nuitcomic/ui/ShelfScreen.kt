package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.data.StoredComic

@Composable
internal fun ShelfScreen(
    model: AppViewModel,
    comics: List<StoredComic>,
    state: ShelfUiState,
    onComic: (Comic) -> Unit,
    modifier: Modifier,
) {
    var confirmDelete by rememberSaveable { mutableStateOf(false) }
    val click: (StoredComic) -> Unit = { stored ->
        if (state.editing) state.selected = if (stored.comic.id in state.selected) state.selected - stored.comic.id else state.selected + stored.comic.id
        else onComic(stored.comic)
    }
    Column(modifier.fillMaxSize()) {
        TabRow(if (state.collection) 0 else 1) {
            Tab(selected = state.collection, enabled = !state.editing, onClick = { state.collection = true }, text = { Text(stringResource(R.string.shelf_collections)) })
            Tab(selected = !state.collection, enabled = !state.editing, onClick = { state.collection = false }, text = { Text(stringResource(R.string.shelf_recent)) })
        }
        if (comics.isEmpty()) {
            Box(Modifier.weight(1f).fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                Text(stringResource(R.string.shelf_empty), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        } else if (state.grid) {
            LazyVerticalGrid(
                columns = GridCells.Adaptive(100.dp),
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                items(comics, key = { it.comic.id }) { stored ->
                    ComicCard(stored.comic, { click(stored) }, selected = stored.comic.id in state.selected, subtitle = progressText(stored))
                }
            }
        } else {
            LazyColumn(Modifier.weight(1f)) {
                items(comics, key = { it.comic.id }) { stored ->
                    ComicRow(stored.comic, { click(stored) }, selected = stored.comic.id in state.selected, subtitle = progressText(stored))
                }
            }
        }
        if (state.editing) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                val allSelected = comics.isNotEmpty() && comics.all { it.comic.id in state.selected }
                TextButton(onClick = { state.selected = if (allSelected) emptyList() else comics.map { it.comic.id } }) {
                    Text(stringResource(if (allSelected) R.string.shelf_deselect_all else R.string.shelf_select_all))
                }
                TextButton(onClick = { confirmDelete = true }, enabled = state.selected.isNotEmpty()) {
                    Text(stringResource(R.string.shelf_delete_count, state.selected.size), color = MaterialTheme.colorScheme.error)
                }
            }
        }
    }
    if (confirmDelete) AlertDialog(
        onDismissRequest = { confirmDelete = false },
        title = { Text(stringResource(if (state.collection) R.string.shelf_delete_collections else R.string.shelf_delete_history)) },
        text = { Text(stringResource(if (state.collection) R.string.shelf_delete_collections_body else R.string.shelf_delete_history_body)) },
        confirmButton = {
            TextButton(onClick = {
                model.removeLibraryItems(state.selected.toSet(), state.collection)
                state.selected = emptyList()
                state.editing = false
                confirmDelete = false
            }) { Text(stringResource(R.string.common_delete), color = MaterialTheme.colorScheme.error) }
        },
        dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text(stringResource(R.string.common_cancel)) } },
    )
}

@Composable
internal fun ShelfToolbarActions(state: ShelfUiState, hasComics: Boolean) {
    var menu by remember { mutableStateOf(false) }
    if (state.editing) {
        TextButton(onClick = { state.editing = false; state.selected = emptyList() }) {
            Text(stringResource(R.string.common_done))
        }
    } else {
        Box {
            IconButton(onClick = { menu = true }) {
                Icon(Icons.Default.MoreVert, stringResource(R.string.shelf_options))
            }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.common_select)) },
                    enabled = hasComics,
                    onClick = { state.editing = true; state.selected = emptyList(); menu = false },
                )
                DropdownMenuItem(
                    text = { Text(stringResource(if (state.grid) R.string.shelf_list else R.string.shelf_grid)) },
                    onClick = { state.toggleLayout(); menu = false },
                )
                HorizontalDivider()
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.shelf_sort_recent) + if (!state.sortByTitle) " ✓" else "") },
                    onClick = { state.updateSortByTitle(false); menu = false },
                )
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.shelf_sort_title) + if (state.sortByTitle) " ✓" else "") },
                    onClick = { state.updateSortByTitle(true); menu = false },
                )
            }
        }
    }
}

@Composable
private fun progressText(comic: StoredComic): String =
    if (comic.lastReadChapterIndex >= 0) stringResource(R.string.shelf_progress, comic.lastReadChapterIndex + 1, comic.chapterCount)
    else stringResource(R.string.shelf_unread)
