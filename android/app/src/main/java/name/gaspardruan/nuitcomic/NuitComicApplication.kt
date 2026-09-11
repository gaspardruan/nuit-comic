package name.gaspardruan.nuitcomic

import android.app.Application
import android.content.Context
import androidx.datastore.preferences.preferencesDataStore
import coil3.ImageLoader
import coil3.SingletonImageLoader
import coil3.memory.MemoryCache
import coil3.network.okhttp.OkHttpNetworkFetcherFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.data.ComicRepository
import name.gaspardruan.nuitcomic.data.ServerConfig
import name.gaspardruan.nuitcomic.reader.ReaderImages

val Context.readerPreferences by preferencesDataStore("reader-preferences")

class NuitComicApplication : Application(), SingletonImageLoader.Factory {
    val repository by lazy { ComicRepository(this) }
    val readerImages by lazy { ReaderImages(this, repository.client) }
    private val saveScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val saves = Channel<ReadingSave>(Channel.UNLIMITED)
    val saveError = MutableStateFlow<String?>(null)
    private var latestSave: ReadingSave? = null

    override fun onCreate() {
        super.onCreate()
        saveScope.launch {
            for (save in saves) {
                try {
                    repository.recordReading(save.comic, save.chapter, save.page, save.chapterCount)
                    saveError.value = null
                } catch (error: Exception) {
                    saveError.value = error.localizedMessage ?: "Unable to save reading position"
                }
            }
        }
    }

    fun saveReading(save: ReadingSave) {
        latestSave = save
        saves.trySend(save)
    }
    fun retrySave() { latestSave?.let { saves.trySend(it) } }

    override fun newImageLoader(context: Context): ImageLoader = ImageLoader.Builder(context)
        .components {
            add(OkHttpNetworkFetcherFactory(callFactory = {
                repository.client.newBuilder().addInterceptor { chain ->
                    chain.proceed(chain.request().newBuilder().header("Referer", ServerConfig.referer).build())
                }.build()
            }))
        }
        .memoryCache { MemoryCache.Builder().maxSizePercent(context, 0.10).build() }
        .build()

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= TRIM_MEMORY_RUNNING_LOW) readerImages.clearMemory()
    }
}

data class ReadingSave(val comic: Comic, val chapter: Int, val page: Int, val chapterCount: Int)
