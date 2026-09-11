package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.StarHalf
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
internal fun StarRating(score: Double) {
    Row {
        repeat(5) { index ->
            val full = score >= index + 1
            val half = score >= index + 0.5
            Icon(
                imageVector = when {
                    full -> Icons.Default.Star
                    half -> Icons.AutoMirrored.Filled.StarHalf
                    else -> Icons.Default.StarBorder
                },
                contentDescription = null,
                tint = if (half) Color(0xFFFFB300) else MaterialTheme.colorScheme.outline,
                modifier = Modifier.size(16.dp),
            )
        }
    }
}
