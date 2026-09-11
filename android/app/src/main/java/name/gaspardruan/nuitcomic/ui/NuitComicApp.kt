package name.gaspardruan.nuitcomic.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.imePadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmarks
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.data.ComicRepository

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NuitComicApp(repository: ComicRepository, readerActive: Boolean = false,
                onRead: (Comic, List<Chapter>, Int, Int) -> Unit) {
    val model: AppViewModel = viewModel(factory = AppViewModel.Factory(repository))
    val tab by model.tab.collectAsStateWithLifecycle()
    val destinations by model.destinations.collectAsStateWithLifecycle()
    val destination = destinations.lastOrNull()
    val library by model.library.collectAsStateWithLifecycle(emptyList())
    val shelfState = rememberShelfUiState()
    val shelfComics = remember(library, shelfState.collection, shelfState.sortByTitle) {
        shelfState.visibleComics(library)
    }
    val availableUpdate by model.availableUpdate.collectAsStateWithLifecycle()
    var dismissedVersion by rememberSaveable { mutableStateOf<String?>(null) }
    val uri = LocalUriHandler.current
    val screenStates = rememberSaveableStateHolder()
    val messages = remember { SnackbarHostState() }
    LaunchedEffect(model) { model.messages.collect { messages.showSnackbar(it) } }
    BackHandler(enabled = !readerActive && (destination != null || tab != 0)) {
        if (destination != null) model.back() else model.selectTab(0)
    }
    val tabs = listOf(R.string.tab_home, R.string.tab_shelf, R.string.tab_search)
    val icons = listOf(Icons.Default.Home, Icons.Default.Bookmarks, Icons.Default.Search)
    Scaffold(
        modifier = Modifier.imePadding(),
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        when (destination) {
                            is Destination.Detail -> destination.comic.title
                            is Destination.Section -> stringResource(destination.section.titleResource)
                            Destination.About -> stringResource(R.string.about_title)
                            null -> stringResource(tabs[tab])
                        },
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                },
                navigationIcon = {
                    if (destination != null) IconButton(onClick = model::back) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(R.string.common_back))
                    }
                },
                actions = {
                    if (destination == null && tab == 0) IconButton(onClick = model::reloadHome) {
                        Icon(Icons.Default.Refresh, stringResource(R.string.common_refresh))
                    }
                    if (destination == null && tab == 1) {
                        ShelfToolbarActions(shelfState, hasComics = shelfComics.isNotEmpty())
                    }
                    if (destination == null && tab == 2) IconButton(onClick = { model.navigate(Destination.About) }) {
                        Icon(Icons.Default.Info, stringResource(R.string.about_title))
                    }
                },
            )
        },
        bottomBar = {
            if (destination == null) NavigationBar {
                tabs.forEachIndexed { index, label ->
                    NavigationBarItem(
                        selected = tab == index,
                        onClick = { model.selectTab(index) },
                        icon = { Icon(icons[index], null) },
                        label = { Text(stringResource(label)) },
                    )
                }
            }
        },
        snackbarHost = { SnackbarHost(messages) },
    ) { padding ->
        val modifier = Modifier.padding(padding)
        val openComic: (Comic) -> Unit = { model.navigate(Destination.Detail(it)) }
        val screenKey = when (destination) {
            is Destination.Detail -> "detail-${destination.comic.id}"
            is Destination.Section -> "section-${destination.section.name}"
            Destination.About -> "about"
            null -> "tab-$tab"
        }
        screenStates.SaveableStateProvider(screenKey) {
            when (destination) {
                is Destination.Detail -> ComicDetailScreen(
                    comic = destination.comic,
                    model = model,
                    storedComic = library.firstOrNull { it.comic.id == destination.comic.id },
                    onComic = openComic,
                    onRead = onRead,
                    modifier = modifier,
                )
                is Destination.Section -> SectionScreen(model, openComic, modifier)
                Destination.About -> AboutScreen(model, modifier)
                null -> when (tab) {
                    0 -> HomeScreen(model, openComic, modifier)
                    1 -> ShelfScreen(model, shelfComics, shelfState, openComic, modifier)
                    else -> SearchScreen(model, openComic, modifier)
                }
            }
        }
    }
    availableUpdate?.takeIf { !readerActive && it.version != dismissedVersion }?.let { update ->
        AlertDialog(
            onDismissRequest = { dismissedVersion = update.version },
            title = { Text(stringResource(R.string.update_title)) },
            text = { Text(stringResource(R.string.update_message, update.version)) },
            confirmButton = {
                TextButton(onClick = { dismissedVersion = update.version; uri.openUri(update.url) }) {
                    Text(stringResource(R.string.update_download))
                }
            },
            dismissButton = { TextButton(onClick = { dismissedVersion = update.version }) { Text(stringResource(R.string.update_later)) } },
        )
    }
}
