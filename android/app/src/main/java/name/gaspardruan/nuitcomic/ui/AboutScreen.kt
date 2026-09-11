package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.OpenInNew
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import name.gaspardruan.nuitcomic.BuildConfig
import name.gaspardruan.nuitcomic.R
import java.text.DateFormat
import java.util.Date

@Composable
internal fun AboutScreen(model: AppViewModel, modifier: Modifier) {
    val status by model.searchStatus.collectAsStateWithLifecycle()
    val update by model.availableUpdate.collectAsStateWithLifecycle()
    val uri = LocalUriHandler.current
    LazyColumn(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        item {
            Column(Modifier.padding(horizontal = 20.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("NuitComic", style = MaterialTheme.typography.headlineMedium)
                Text(stringResource(R.string.about_intro), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        item {
            OutlinedCard(Modifier.padding(horizontal = 16.dp)) {
                ListItem(headlineContent = { Text(stringResource(R.string.about_version)) }, trailingContent = { Text(BuildConfig.VERSION_NAME) })
                HorizontalDivider()
                ListItem(headlineContent = { Text(stringResource(R.string.about_comic_count)) }, trailingContent = { Text(status.comicCount.toString()) })
                HorizontalDivider()
                ListItem(
                    headlineContent = { Text(stringResource(R.string.about_last_sync)) },
                    supportingContent = { Text(status.lastSyncAt?.let { DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT).format(Date(it)) } ?: stringResource(R.string.about_not_synced)) },
                )
                TextButton(onClick = { model.refreshSearch(true) }, enabled = !status.isRefreshing, modifier = Modifier.padding(horizontal = 8.dp)) {
                    Text(stringResource(if (status.isRefreshing) R.string.search_preparing else R.string.about_refresh_index))
                }
            }
        }
        item {
            Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(stringResource(R.string.about_links), style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(8.dp))
                AboutLink("GitHub", "https://github.com/gaspardruan/nuit-comic", uri::openUri)
                AboutLink("Bilibili", "https://space.bilibili.com/470093851", uri::openUri)
                // Android users must choose an APK asset, never the iOS update manifest's IPA.
                AboutLink(stringResource(R.string.about_android_releases), "https://github.com/gaspardruan/nuit-comic/releases", uri::openUri)
            }
        }
        update?.let { release ->
            item {
                Column(Modifier.fillMaxWidth().padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(stringResource(R.string.update_message, release.version), style = MaterialTheme.typography.titleMedium)
                    if (release.notes.isNotBlank()) Text(release.notes, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    AboutLink(stringResource(R.string.update_download), release.url, uri::openUri)
                }
            }
        }
    }
}

@Composable
private fun AboutLink(title: String, url: String, open: (String) -> Unit) {
    TextButton(onClick = { open(url) }, modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(title)
            Icon(Icons.Default.OpenInNew, null)
        }
    }
}
