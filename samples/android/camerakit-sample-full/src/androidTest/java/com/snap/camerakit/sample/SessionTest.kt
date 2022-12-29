package com.snap.camerakit.sample

import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.snap.camerakit.Session
import com.snap.camerakit.invoke
import com.snap.camerakit.lenses.LENS_GROUP_ID_BUNDLED
import com.snap.camerakit.lenses.LensesComponent.Repository.QueryCriteria
import com.snap.camerakit.lenses.apply
import com.snap.camerakit.lenses.get
import com.snap.camerakit.lenses.whenHasFirst
import com.snap.camerakit.sourceFrom
import com.snap.camerakit.toBitmap
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.fail

/**
 * Demonstrates use of [Session] in UI-less instrumentation tests.
 */
@RunWith(AndroidJUnit4::class)
class SessionTest {

    @get:Rule
    val temporaryFolder = TemporaryFolder()

    /**
     * Basic test that opens a new CameraKit [Session] with defaults, applies a bundled lens and captures processed
     * video frame into a [android.graphics.Bitmap] that is validated only by asserting its size but could potentially
     * be compared to a reference image by [PSNR](https://en.wikipedia.org/wiki/Peak_signal-to-noise_ratio).
     *
     * To simulate real camera input, pre-recorded video is copied and attached using [sourceFrom] helper method.
     * The [toBitmap] is used to render [com.snap.camerakit.ImageProcessor] output to [android.graphics.Bitmap]
     * which can be inspected using Android Studio debugger or dumped to disk for further post-test processing
     * and validation.
     */
    @Test
    fun openSession_applyLens_outputBitmap() {
        val targetContext = InstrumentationRegistry.getInstrumentation().targetContext
        val videoFile = temporaryFolder.newFile().also { file ->
            this.javaClass.classLoader!!.getResourceAsStream("object_pet_video.mp4").use { inputStream ->
                file.outputStream().use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
        }

        Session(targetContext) {
            imageProcessorSource(
                sourceFrom(
                    context = targetContext,
                    file = videoFile,
                    rotationDegrees = 0
                )
            )
        }.use { session ->
            val applied = CountDownLatch(1)

            session.lenses.repository.get(QueryCriteria.Available(LENS_GROUP_ID_BUNDLED)) { result ->
                result.whenHasFirst { lens ->
                    session.lenses.processor.apply(lens) { success ->
                        if (success) {
                            applied.countDown()
                        } else {
                            fail("Expected lens to successfully apply")
                        }
                    }
                }
                acceptIfLegalPromptIsDisplayed()
            }

            if (!applied.await(10L, TimeUnit.SECONDS)) {
                throw RuntimeException("Timed out while waiting for lens to apply")
            }

            // Render lens for a few frames
            SystemClock.sleep(1_000L)

            val bitmap = session.processor.toBitmap(720, 1280, rotationDegrees = 0)

            assertNotNull(bitmap)
            assertEquals(720, bitmap.width)
            assertEquals(1280, bitmap.height)
        }
    }
}
