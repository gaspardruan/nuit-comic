package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import name.gaspardruan.nuitcomic.R
import name.gaspardruan.nuitcomic.data.Comic
import name.gaspardruan.nuitcomic.data.HomeSection

internal val HomeSection.titleResource: Int
    get() = when (this) {
        HomeSection.NEW -> R.string.section_new
        HomeSection.UPDATED -> R.string.section_updated
        HomeSection.RECOMMENDED -> R.string.section_recommended
        HomeSection.MOST_READ -> R.string.section_most_read
        HomeSection.MOST_FOLLOWED -> R.string.section_most_followed
        HomeSection.COMPLETED -> R.string.section_completed
        HomeSection.MOST_SEARCHED -> R.string.section_most_searched
    }

@Composable
internal fun ComicCover(comic: Comic, modifier: Modifier = Modifier, selected: Boolean = false, preferCover: Boolean = false) {
    if (preferCover) {
        DetailComicCover(comic, modifier)
        return
    }
    val primary = comic.coverUrl
    val fallback = comic.cover
    var useFallback by remember(primary, fallback) { mutableStateOf(false) }
    // The container owns its dimensions, so image decoding never changes the row height.
    Box(
        modifier.clip(RoundedCornerShape(6.dp)).background(MaterialTheme.colorScheme.surfaceContainerHighest),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Default.Book, null, Modifier.size(30.dp), tint = MaterialTheme.colorScheme.outline)
        AsyncImage(
            model = if (useFallback && fallback.isNotBlank()) fallback else primary,
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.matchParentSize(),
            onError = { useFallback = true },
        )
        if (selected) {
            Box(Modifier.matchParentSize().background(MaterialTheme.colorScheme.primary.copy(alpha = 0.22f)))
            Icon(
                Icons.Default.CheckCircle,
                stringResource(R.string.shelf_selected),
                Modifier.align(Alignment.TopEnd).padding(6.dp),
                tint = MaterialTheme.colorScheme.primary,
            )
        }
    }
}

@Composable
private fun DetailComicCover(comic: Comic, modifier: Modifier = Modifier) {
    val primary = comic.cover.ifBlank { comic.image }
    val fallback = comic.image
    var useFallback by remember(primary, fallback) { mutableStateOf(false) }
    val imageUrl = if (useFallback && fallback.isNotBlank()) fallback else primary
    var imageRatio by remember(imageUrl) { mutableStateOf<Float?>(null) }
    var loaded by remember(imageUrl) { mutableStateOf(false) }
    // Keep the reserved space fixed, but round only the fitted image's visible bounds.
    BoxWithConstraints(modifier, contentAlignment = Alignment.Center) {
        if (!loaded) {
            Box(
                Modifier.matchParentSize().clip(RoundedCornerShape(6.dp))
                    .background(MaterialTheme.colorScheme.surfaceContainerHighest),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Default.Book, null, Modifier.size(30.dp), tint = MaterialTheme.colorScheme.outline)
            }
        }
        val ratio = imageRatio
        val imageModifier = if (ratio != null) {
            val width = minOf(maxWidth, maxHeight * ratio)
            Modifier.size(width, width / ratio)
        } else {
            Modifier.matchParentSize()
        }
        AsyncImage(
            model = imageUrl,
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = imageModifier.clip(RoundedCornerShape(6.dp)),
            onSuccess = { state ->
                val image = state.result.image
                if (image.width > 0 && image.height > 0) imageRatio = image.width.toFloat() / image.height
                loaded = true
            },
            onError = { useFallback = true },
        )
    }
}

@Composable
internal fun ComicCard(comic: Comic, onClick: () -> Unit, modifier: Modifier = Modifier, selected: Boolean = false, subtitle: String? = null) {
    Column(modifier.clickable(onClick = onClick), verticalArrangement = Arrangement.spacedBy(5.dp)) {
        ComicCover(comic, Modifier.fillMaxWidth().aspectRatio(5f / 7f), selected)
        Text(comic.title, style = MaterialTheme.typography.bodyMedium, maxLines = 1, overflow = TextOverflow.Ellipsis)
        Text(
            subtitle ?: comic.keyword.split(',').filter(String::isNotBlank).take(2).joinToString(" ").ifBlank { " " },
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

internal fun LazyListScope.comicGrid(comics: List<Comic>, prefix: String, columns: Int, onComic: (Comic) -> Unit) {
    items(comics.chunked(columns), key = { "$prefix-${it.first().id}" }) { row ->
        Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            row.forEach { comic -> ComicCard(comic, { onComic(comic) }, Modifier.weight(1f)) }
            repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
        }
    }
}

@Composable
internal fun ComicRow(comic: Comic, onClick: () -> Unit, modifier: Modifier = Modifier, query: String = "", selected: Boolean = false, subtitle: String? = null) {
    Row(
        modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ComicCover(comic, Modifier.width(90.dp).height(126.dp), selected)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(7.dp)) {
            Text(highlighted(comic.title, query), style = MaterialTheme.typography.titleSmall, maxLines = 2, overflow = TextOverflow.Ellipsis)
            Text(
                subtitle ?: comic.keyword.replace(",", " · "),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(highlighted(comic.description, query), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 3, overflow = TextOverflow.Ellipsis)
        }
        Icon(Icons.Default.ChevronRight, null, tint = MaterialTheme.colorScheme.outline)
    }
}

@Composable
private fun highlighted(text: String, query: String): AnnotatedString {
    val needle = query.trim()
    if (needle.isEmpty()) return AnnotatedString(text)
    val highlight = SpanStyle(color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
    return buildAnnotatedString {
        var start = 0
        var match = text.indexOf(needle, ignoreCase = true)
        while (match >= 0) {
            append(text.substring(start, match))
            withStyle(highlight) { append(text.substring(match, match + needle.length)) }
            start = match + needle.length
            match = text.indexOf(needle, startIndex = start, ignoreCase = true)
        }
        append(text.substring(start))
    }
}

@Composable
internal fun LoadingState(modifier: Modifier = Modifier, message: String = stringResource(R.string.common_loading)) {
    Column(modifier.fillMaxSize().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        CircularProgressIndicator(Modifier.size(30.dp))
        Spacer(Modifier.height(16.dp))
        Text(message, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
internal fun ErrorState(message: String?, onRetry: () -> Unit, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth().padding(28.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(stringResource(R.string.common_load_failed), style = MaterialTheme.typography.titleMedium)
        if (!message.isNullOrBlank()) Text(message, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        TextButton(onClick = onRetry) { Text(stringResource(R.string.common_retry)) }
    }
}
