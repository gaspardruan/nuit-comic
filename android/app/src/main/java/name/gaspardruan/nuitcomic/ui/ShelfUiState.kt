package name.gaspardruan.nuitcomic.ui

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import name.gaspardruan.nuitcomic.data.StoredComic
import java.text.Collator

@Stable
internal class ShelfUiState(
    private val preferences: SharedPreferences,
    collection: Boolean = true,
    editing: Boolean = false,
    selected: List<Int> = emptyList(),
) {
    var grid by mutableStateOf(preferences.getBoolean("grid", true))
        private set
    var sortByTitle by mutableStateOf(preferences.getBoolean("sortByTitle", false))
        private set
    var collection by mutableStateOf(collection)
    var editing by mutableStateOf(editing)
    var selected by mutableStateOf(selected)

    fun toggleLayout() {
        grid = !grid
        preferences.edit().putBoolean("grid", grid).apply()
    }

    fun updateSortByTitle(value: Boolean) {
        sortByTitle = value
        preferences.edit().putBoolean("sortByTitle", value).apply()
    }

    fun visibleComics(library: List<StoredComic>): List<StoredComic> {
        val filtered = library.filter { if (collection) it.isCollected else it.lastReadChapterIndex >= 0 }
        return if (sortByTitle) filtered.sortedWith(compareBy(Collator.getInstance()) { it.comic.title })
        else filtered.sortedByDescending { it.updatedAt }
    }
}

@Composable
internal fun rememberShelfUiState(): ShelfUiState {
    val context = LocalContext.current
    val preferences = remember(context) { context.getSharedPreferences("shelf", Context.MODE_PRIVATE) }
    return rememberSaveable(
        saver = listSaver<ShelfUiState, Any>(
            save = { listOf(it.collection, it.editing, it.selected.toIntArray()) },
            restore = {
                ShelfUiState(
                    preferences = preferences,
                    collection = it[0] as Boolean,
                    editing = it[1] as Boolean,
                    selected = (it[2] as IntArray).toList(),
                )
            },
        ),
    ) { ShelfUiState(preferences) }
}
