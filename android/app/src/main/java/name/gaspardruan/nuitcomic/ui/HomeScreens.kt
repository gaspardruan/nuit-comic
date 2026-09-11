package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.flow.distinctUntilChanged
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.data.HomeSection

@Composable
internal fun HomeScreen(model: AppViewModel, onComic: (Comic) -> Unit, modifier: Modifier) {
    val home by model.home.collectAsStateWithLifecycle()
    val random by model.random.collectAsStateWithLifecycle()
    val columns = (LocalConfiguration.current.screenWidthDp / 150).coerceIn(3, 6)
    val feed = home.value
    if (feed == null) {
        Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            if (home.loading) LoadingState() else ErrorState(home.error, model::reloadHome)
        }
        return
    }
    LazyColumn(modifier.fillMaxSize()) {
        if (home.loading) item { LoadingState(Modifier.height(64.dp)) }
        if (home.error != null) item { ErrorState(home.error, model::reloadHome) }
        val sections = listOf(HomeSection.NEW, HomeSection.UPDATED, HomeSection.MOST_READ, HomeSection.MOST_FOLLOWED, HomeSection.COMPLETED, HomeSection.RECOMMENDED, HomeSection.MOST_SEARCHED)
        sections.forEach { section ->
            val comics = feed.sections[section].orEmpty()
            if (comics.isNotEmpty()) {
                item(key = "heading-$section") {
                    Row(
                        Modifier.fillMaxWidth().then(
                            if (section != HomeSection.MOST_SEARCHED) Modifier.clickable { model.navigate(Destination.Section(section)) } else Modifier
                        ).padding(start = 16.dp, end = 12.dp, top = 24.dp, bottom = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(stringResource(section.titleResource), style = MaterialTheme.typography.titleLarge, modifier = Modifier.weight(1f))
                        if (section != HomeSection.MOST_SEARCHED) Icon(Icons.Default.ChevronRight, stringResource(R.string.common_see_all), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                comicGrid(comics, section.name, columns, onComic)
            }
        }
        item(key = "random-heading") {
            Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 8.dp, top = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.section_random), Modifier.weight(1f), style = MaterialTheme.typography.titleLarge)
                IconButton(onClick = model::refreshRandom, enabled = !random.loading) { Icon(Icons.Default.Refresh, stringResource(R.string.common_refresh)) }
            }
        }
        if (random.loading && random.value == null) item { LoadingState(Modifier.height(110.dp)) }
        if (random.error != null) item { ErrorState(random.error, model::refreshRandom) }
        comicGrid(random.value.orEmpty(), "random", columns, onComic)
        item { Box(Modifier.height(24.dp)) }
    }
}

@Composable
internal fun SectionScreen(model: AppViewModel, onComic: (Comic) -> Unit, modifier: Modifier) {
    val state by model.section.collectAsStateWithLifecycle()
    val scroll = rememberLazyListState()
    LaunchedEffect(scroll, state.comics.size, state.loading, state.finished, state.error) {
        snapshotFlow { (scroll.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1) >= state.comics.size - 4 }
            .distinctUntilChanged()
            .collect { nearEnd ->
                if (nearEnd && !state.loading && !state.finished && state.error == null) model.nextPage()
            }
    }
    LazyColumn(modifier.fillMaxSize(), state = scroll, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        items(state.comics, key = { it.id }) { comic -> ComicRow(comic, { onComic(comic) }) }
        item {
            when {
                state.loading -> LoadingState(Modifier.height(110.dp))
                state.error != null -> ErrorState(state.error, model::nextPage)
                state.finished -> Text(
                    stringResource(if (state.comics.isEmpty()) R.string.common_empty else R.string.common_end),
                    Modifier.fillMaxWidth().padding(24.dp),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}
