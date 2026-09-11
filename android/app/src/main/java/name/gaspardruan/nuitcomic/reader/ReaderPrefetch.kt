package name.gaspardruan.nuitcomic.reader

import kotlin.math.abs

internal data class PagePiece(val page: Int, val tile: Int, val key: String)

/** Plan only nearby, offscreen strips; visible strips use the foreground decoder. */
internal fun nearbyReaderTiles(
    pages: List<ReaderPage>,
    metadata: Map<String, PageInfo>,
    visible: List<PagePiece>,
    width: Int,
    viewportHeight: Int,
    horizontal: Boolean,
    byteBudget: Long,
): List<PagePiece> {
    if (visible.isEmpty()) return emptyList()
    val visibleKeys = visible.map { pages[it.page].url to it.tile }.toSet()
    val candidates = linkedMapOf<Pair<String, Int>, Pair<PagePiece, Float>>()

    fun piece(page: Int, tile: Int) = PagePiece(page, tile, "${pages[page].key}:$tile")
    fun add(candidate: PagePiece, distance: Float) {
        val key = pages[candidate.page].url to candidate.tile
        if (key !in visibleKeys && distance < (candidates[key]?.second ?: Float.MAX_VALUE)) {
            candidates[key] = candidate to distance
        }
    }
    fun height(candidate: PagePiece): Float {
        val info = metadata.getValue(pages[candidate.page].url)
        return info.tileHeight(candidate.tile, width).toFloat() * width / info.width
    }
    fun adjacent(current: PagePiece, direction: Int): PagePiece? {
        val info = metadata[pages[current.page].url] ?: return null
        val tile = current.tile + direction
        if (tile in 0 until info.tileCount(width)) return piece(current.page, tile)
        val page = current.page + direction
        if (page !in pages.indices) return null
        val nextInfo = metadata[pages[page].url] ?: return null
        return piece(page, if (direction > 0) 0 else nextInfo.tileCount(width) - 1)
    }
    fun collect(direction: Int, distanceLimit: Int) {
        var current = if (direction > 0) visible.last() else visible.first()
        var distance = 0f
        repeat(10) {
            if (distance >= distanceLimit) return
            val next = adjacent(current, direction) ?: return
            add(next, distance)
            distance += height(next)
            current = next
        }
    }

    collect(direction = 1, distanceLimit = viewportHeight * 2)
    collect(direction = -1, distanceLimit = viewportHeight)
    if (horizontal) {
        // A sideways swipe reveals another page's first viewport, even midway through a long image.
        for (offset in listOf(1, -1, 2)) {
            val page = visible.first().page + offset
            if (page !in pages.indices) continue
            val info = metadata[pages[page].url] ?: continue
            var distance = 0f
            for (tile in 0 until minOf(info.tileCount(width), 10)) {
                if (distance >= viewportHeight) break
                val next = piece(page, tile)
                // Prepare the whole next viewport before spending the budget on other offscreen strips.
                val priority = if (offset == 1) distance - viewportHeight
                    else viewportHeight * (abs(offset) - 0.75f) + distance
                add(next, priority)
                distance += height(next)
            }
        }
    }

    var remainingBytes = byteBudget
    return buildList {
        for ((candidate, _) in candidates.values.sortedBy { it.second }) {
            val info = metadata.getValue(pages[candidate.page].url)
            val bytes = info.tileMemoryBytes(candidate.tile, width)
            if (bytes > remainingBytes) continue
            add(candidate)
            remainingBytes -= bytes
            if (size == 10) break
        }
    }
}
