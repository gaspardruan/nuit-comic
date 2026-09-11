package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.data.Comic

@Composable
internal fun SearchScreen(model: AppViewModel, onComic: (Comic) -> Unit, modifier: Modifier) {
    val query by model.query.collectAsStateWithLifecycle()
    val results by model.results.collectAsStateWithLifecycle()
    val status by model.searchStatus.collectAsStateWithLifecycle()
    val history by model.searchHistory.collectAsStateWithLifecycle(emptyList())
    val focus = LocalFocusManager.current
    var confirmClear by rememberSaveable { mutableStateOf(false) }
    val scroll = rememberLazyListState()
    var scrolledQuery by rememberSaveable { mutableStateOf(query) }
    LaunchedEffect(query) {
        if (scrolledQuery != query) {
            scrolledQuery = query
            scroll.scrollToItem(0)
        }
    }
    Column(modifier.fillMaxSize()) {
        OutlinedTextField(
            value = query,
            onValueChange = model::search,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            placeholder = { Text(stringResource(R.string.search_prompt), style = MaterialTheme.typography.bodyMedium) },
            leadingIcon = { Icon(Icons.Default.Search, null) },
            trailingIcon = {
                if (query.isNotEmpty()) IconButton(onClick = { model.search("") }) { Icon(Icons.Default.Close, stringResource(R.string.common_clear)) }
            },
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
            keyboardActions = KeyboardActions(onSearch = { model.submitSearch(); focus.clearFocus() }),
        )
        if (status.isRefreshing) LinearProgressIndicator(Modifier.fillMaxWidth())
        if (status.hasIndex && status.error != null) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.search_cached_error), Modifier.weight(1f), style = MaterialTheme.typography.bodySmall)
                TextButton(onClick = { model.refreshSearch(true) }) { Text(stringResource(R.string.common_retry)) }
            }
        }
        when {
            !status.hasIndex -> Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                if (status.error != null && !status.isRefreshing) ErrorState(status.error, { model.refreshSearch(true) })
                else LoadingState(message = stringResource(R.string.search_preparing))
            }
            query.isBlank() -> {
                Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(stringResource(R.string.search_history), Modifier.weight(1f), style = MaterialTheme.typography.titleMedium)
                    if (history.isNotEmpty()) TextButton(onClick = { confirmClear = true }) { Text(stringResource(R.string.common_clear)) }
                }
                LazyColumn(Modifier.weight(1f), state = scroll) {
                    if (history.isEmpty()) item { Text(stringResource(R.string.search_history_empty), Modifier.padding(20.dp), color = MaterialTheme.colorScheme.onSurfaceVariant) }
                    items(history, key = { it }) { text ->
                        Row(
                            Modifier.fillMaxWidth().clickable { model.search(text); model.submitSearch(); focus.clearFocus() }.padding(horizontal = 20.dp, vertical = 15.dp),
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(Icons.Default.History, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text(text, style = MaterialTheme.typography.bodyLarge)
                        }
                    }
                }
            }
            results.loading -> LoadingState(Modifier.weight(1f))
            results.error != null -> ErrorState(results.error, { model.refreshSearch(true) })
            results.value.isNullOrEmpty() -> Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text(stringResource(R.string.search_no_results), color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            else -> LazyColumn(Modifier.weight(1f), state = scroll) {
                items(results.value.orEmpty(), key = { it.id }) { comic ->
                    ComicRow(comic, { model.submitSearch(); focus.clearFocus(); onComic(comic) }, query = query)
                }
                item {
                    Text(stringResource(R.string.search_result_count, results.value.orEmpty().size), Modifier.padding(20.dp), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
    if (confirmClear) AlertDialog(
        onDismissRequest = { confirmClear = false },
        title = { Text(stringResource(R.string.search_clear_title)) },
        text = { Text(stringResource(R.string.search_clear_body)) },
        confirmButton = { TextButton(onClick = { model.clearSearchHistory(); confirmClear = false }) { Text(stringResource(R.string.common_clear)) } },
        dismissButton = { TextButton(onClick = { confirmClear = false }) { Text(stringResource(R.string.common_cancel)) } },
    )
}
