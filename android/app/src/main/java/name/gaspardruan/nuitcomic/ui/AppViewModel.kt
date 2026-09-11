package name.gaspardruan.nuitcomic.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import name.gaspardruan.nuitcomic.data.Chapter
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.data.ComicRepository
import name.gaspardruan.nuitcomic.data.HomeFeed
import name.gaspardruan.nuitcomic.data.HomeSection
import name.gaspardruan.nuitcomic.data.AndroidRelease
import name.gaspardruan.nuitcomic.data.SearchStatus
import name.gaspardruan.nuitcomic.BuildConfig

internal sealed interface Destination {
    data class Detail(val comic: Comic) : Destination
    data class Section(val section: HomeSection) : Destination
    data object About : Destination
}

internal data class LoadState<T>(val value: T? = null, val loading: Boolean = true, val error: String? = null)
internal data class SectionState(
    val section: HomeSection? = null,
    val comics: List<Comic> = emptyList(),
    val page: Int = 0,
    val loading: Boolean = false,
    val finished: Boolean = false,
    val error: String? = null,
)
private data class SearchRequest(val query: String, val status: SearchStatus, val visible: Boolean)

/** Screen state lives here; repositories own stored data and Compose owns transient controls. */
internal class AppViewModel(private val repository: ComicRepository) : ViewModel() {
    val library = repository.library
    val searchHistory = repository.searchHistory
    val searchStatus = repository.searchStatus

    private val _tab = MutableStateFlow(0)
    val tab = _tab.asStateFlow()
    private val _destinations = MutableStateFlow<List<Destination>>(emptyList())
    val destinations = _destinations.asStateFlow()
    private val _home = MutableStateFlow(LoadState<HomeFeed>())
    val home = _home.asStateFlow()
    private val _random = MutableStateFlow(LoadState<List<Comic>>())
    val random = _random.asStateFlow()
    private val _chapters = MutableStateFlow(LoadState<List<Chapter>>())
    val chapters = _chapters.asStateFlow()
    private val _detailRecommendations = MutableStateFlow(LoadState<List<Comic>>())
    val detailRecommendations = _detailRecommendations.asStateFlow()
    private val _section = MutableStateFlow(SectionState())
    val section = _section.asStateFlow()
    private val _query = MutableStateFlow("")
    val query = _query.asStateFlow()
    private val _results = MutableStateFlow(LoadState<List<Comic>>(emptyList(), loading = false))
    val results = _results.asStateFlow()
    private val _messages = MutableSharedFlow<String>()
    val messages = _messages.asSharedFlow()
    private val _availableUpdate = MutableStateFlow<AndroidRelease?>(null)
    val availableUpdate = _availableUpdate.asStateFlow()
    private var homeJob: Job? = null
    private var randomJob: Job? = null
    private var destinationJob: Job? = null
    private var detailRecommendationsJob: Job? = null

    init {
        reloadHome()
        refreshRandom()
        refreshSearch()
        viewModelScope.launch {
            try {
                val release = repository.latestAndroidRelease()
                if (release != null && newerVersion(release.version, BuildConfig.VERSION_NAME)) _availableUpdate.value = release
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                // A failed optional update check must not interrupt browsing or offline reading.
            }
        }
        viewModelScope.launch {
            combine(_query, repository.searchStatus, _tab, _destinations) { query, status, tab, destinations ->
                SearchRequest(query.trim(), status, tab == 2 && destinations.isEmpty())
            }.collectLatest { (query, status, visible) ->
                    if (!visible) return@collectLatest
                    if (query.isEmpty() || !status.hasIndex) {
                        _results.value = LoadState(emptyList(), loading = false)
                    } else {
                        _results.value = LoadState(loading = true)
                        delay(300)
                        _results.value = load { repository.search(query) }
                    }
                }
        }
    }

    fun selectTab(tab: Int) {
        _tab.value = tab
        _destinations.value = emptyList()
        activate(null)
    }

    fun navigate(destination: Destination) {
        _destinations.update { it + destination }
        activate(destination)
    }

    fun back() {
        _destinations.update { it.dropLast(1) }
        activate(_destinations.value.lastOrNull())
    }

    private fun activate(destination: Destination?) {
        destinationJob?.cancel()
        detailRecommendationsJob?.cancel()
        _section.update { it.copy(loading = false) }
        when (destination) {
            is Destination.Detail -> {
                reloadChapters()
                _detailRecommendations.value = LoadState(_random.value.value?.filter { it.id != destination.comic.id })
                refreshDetailRecommendations()
            }
            is Destination.Section -> {
                if (_section.value.section != destination.section || _section.value.page == 0) {
                    _section.value = SectionState(section = destination.section)
                    nextPage()
                }
            }
            else -> Unit
        }
    }

    fun reloadHome() {
        if (homeJob?.isActive == true) return
        homeJob = viewModelScope.launch {
            val previous = _home.value.value
            _home.update { it.copy(loading = true, error = null) }
            val result = load { repository.home() }
            _home.value = if (result.error != null) result.copy(value = previous) else result
        }
    }

    fun refreshRandom() {
        if (randomJob?.isActive == true) return
        randomJob = viewModelScope.launch {
            val previous = _random.value.value
            _random.update { it.copy(loading = true, error = null) }
            val result = load { repository.random() }
            _random.value = if (result.error != null) result.copy(value = previous) else result
        }
    }

    fun reloadChapters() {
        val comic = (_destinations.value.lastOrNull() as? Destination.Detail)?.comic ?: return
        destinationJob?.cancel()
        val cached = repository.cachedChapters(comic.id)
        _chapters.value = LoadState(cached, loading = cached == null)
        destinationJob = viewModelScope.launch {
            val result = load { repository.chapters(comic.id) }
            _chapters.value = if (result.error != null) result.copy(value = cached) else result
        }
    }

    fun refreshDetailRecommendations() {
        val comic = (_destinations.value.lastOrNull() as? Destination.Detail)?.comic ?: return
        detailRecommendationsJob?.cancel()
        val previous = _detailRecommendations.value.value
        _detailRecommendations.value = LoadState(previous)
        detailRecommendationsJob = viewModelScope.launch {
            val result = load { repository.random().filter { it.id != comic.id }.distinctBy { it.id } }
            _detailRecommendations.value = if (result.error != null) result.copy(value = previous) else result
        }
    }

    fun nextPage() {
        val state = _section.value
        val section = state.section ?: return
        if (state.loading || state.finished) return
        _section.value = state.copy(loading = true, error = null)
        destinationJob = viewModelScope.launch {
            try {
                val page = state.page + 1
                val comics = repository.list(section, page)
                val combined = (state.comics + comics).distinctBy { it.id }
                _section.value = state.copy(
                    comics = combined,
                    page = page,
                    finished = combined.size == state.comics.size,
                )
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                _section.value = state.copy(error = error.localizedMessage ?: error.toString())
            }
        }
    }

    fun setCollected(comic: Comic, collected: Boolean, chapterCount: Int) = action {
        repository.setCollected(comic, collected, chapterCount)
    }

    fun removeLibraryItems(ids: Set<Int>, collection: Boolean) = action {
        if (collection) repository.removeCollections(ids) else repository.removeHistory(ids)
    }

    fun search(query: String) { _query.value = query }
    fun submitSearch() = action {
        val query = _query.value.trim()
        if (query.isNotEmpty()) repository.addSearchHistory(query)
    }
    fun clearSearchHistory() = action { repository.clearSearchHistory() }
    fun refreshSearch(force: Boolean = false) = action { repository.refreshSearchIndex(force) }

    private fun action(block: suspend () -> Unit) = viewModelScope.launch {
        try {
            block()
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            _messages.emit(error.localizedMessage ?: error.toString())
        }
    }

    private suspend fun <T> load(block: suspend () -> T): LoadState<T> = try {
        LoadState(block(), loading = false)
    } catch (error: CancellationException) {
        throw error
    } catch (error: Exception) {
        LoadState(loading = false, error = error.localizedMessage ?: error.toString())
    }

    class Factory(private val repository: ComicRepository) : ViewModelProvider.Factory {
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            require(modelClass.isAssignableFrom(AppViewModel::class.java))
            @Suppress("UNCHECKED_CAST")
            return AppViewModel(repository) as T
        }
    }
}

internal fun newerVersion(candidate: String, installed: String): Boolean {
    val next = candidate.split('.').map { it.toIntOrNull() ?: return false }
    val current = installed.split('.').map { it.toIntOrNull() ?: return false }
    if (next.size != 3 || current.size != 3) return false
    return next.zip(current).firstOrNull { (a, b) -> a != b }?.let { (a, b) -> a > b } ?: false
}
