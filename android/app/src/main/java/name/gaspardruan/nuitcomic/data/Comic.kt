package name.gaspardruan.nuitcomic.data

data class Comic(
    val id: Int,
    val title: String,
    val image: String = "",
    val cover: String = "",
    val description: String = "",
    val author: String = "",
    val keyword: String = "",
    val follow: Int = 0,
    val view: Long = 0,
    val isOver: Boolean = false,
    val score: Double = 9.0,
    val updateTime: Long = 0,
) {
    val coverUrl: String get() = image.ifBlank { cover }
}

data class Chapter(val id: Int, val title: String, val images: List<String>)

enum class HomeSection {
    NEW, UPDATED, RECOMMENDED, MOST_READ, MOST_FOLLOWED, COMPLETED, MOST_SEARCHED
}

data class HomeFeed(val sections: Map<HomeSection, List<Comic>>)

data class StoredComic(
    val comic: Comic,
    val isCollected: Boolean,
    // A collected comic that has never been opened has no reading history.
    val lastReadChapterIndex: Int = -1,
    val lastReadPageIndex: Int = 0,
    val chapterCount: Int = 0,
    val updatedAt: Long = 0,
)

data class SearchStatus(
    val hasIndex: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null,
    val comicCount: Int = 0,
    val lastSyncAt: Long? = null,
)

object ServerConfig {
    const val referer = "https://yymh.app/"
    const val apiBaseUrl = "https://yymh.app/home/api"
    const val imageBaseUrl = "https://icnyy.tengxun.best/public"
    const val pageSize = 20

    fun imageUrl(path: String): String {
        val value = path.trim()
        return when {
            value.isEmpty() -> ""
            value.startsWith("https://") || value.startsWith("http://") -> value
            value.startsWith("//") -> "https:$value"
            else -> "$imageBaseUrl/${value.trimStart('/')}"
        }
    }
}
