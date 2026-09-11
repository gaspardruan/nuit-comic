package name.gaspardruan.nuitcomic.data

import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AndroidReleaseTest {
    @Test
    fun updateRequiresAPublishedStableReleaseWithAnAPK() {
        val json = """[
            {"tag_name":"v3.0.0","draft":true,"assets":[{"name":"nuitcomic.apk"}]},
            {"tag_name":"v2.5.0","prerelease":true,"assets":[{"name":"nuitcomic.apk"}]},
            {"tag_name":"v2.1.0","assets":[{"name":"nuitcomic.ipa"}]},
            {"tag_name":"v2.0.0","assets":[{"name":"nuitcomic.apk"}],"body":"Android update","html_url":"https://example.test/release"}
        ]"""
        val release = AndroidReleaseJson.parse(Json.parseToJsonElement(json))
        assertEquals(AndroidRelease("2.0.0", "Android update", "https://example.test/release"), release)
    }

    @Test
    fun iOSOnlyReleaseDoesNotPromptAnAndroidUpdate() {
        assertNull(AndroidReleaseJson.parse(Json.parseToJsonElement("""[
            {"tag_name":"v1.2.0","assets":[{"name":"nuitcomic.ipa"}]}
        ]""")))
    }
}
