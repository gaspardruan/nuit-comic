package name.gaspardruan.nuitcomic.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColors = lightColorScheme(
    primary = Color(0xFF4267A9),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFD8E2FF),
    secondary = Color(0xFF575E71),
    background = Color(0xFFFAFAFC),
    surface = Color(0xFFFAFAFC),
)
private val DarkColors = darkColorScheme(
    primary = Color(0xFFACC7FF),
    primaryContainer = Color(0xFF264A86),
    secondary = Color(0xFFBFC6DC),
    background = Color(0xFF111318),
    surface = Color(0xFF111318),
)

@Composable
fun NuitComicTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors, content = content)
}
