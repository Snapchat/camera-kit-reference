package com.snap.camerakit.sample

import android.Manifest
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.KeyEvent
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.FileProvider
import androidx.lifecycle.LifecycleOwner
import com.snap.camerakit.ImageProcessor
import com.snap.camerakit.lenses.LENS_GROUP_ID_BUNDLED
import com.snap.camerakit.outputFrom
import com.snap.camerakit.support.widget.CameraLayout
import com.snap.camerakit.support.widget.SnapButtonView
import java.io.Closeable
import java.io.File
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import android.content.pm.ResolveInfo
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

private const val TAG = "MainActivity"
private val LENS_GROUPS = arrayOf(
    LENS_GROUP_ID_BUNDLED, // lens group for bundled lenses available in lenses-bundle artifact.
    *BuildConfig.LENS_GROUP_ID_TEST.split(',').toTypedArray() // temporary lens group for testing
)

/**
 * A simple activity which demonstrates how to connect and use a custom implementation of audio and video
 * recording with CameraKit.
 * Video output frames are provided by CameraKit via connecting an output surface.
 * Audio is provided from microphone source in [AudioProcessorSource] which is open to customization.
 * Audio and video encoding is done in [MediaCapture] which produces final output video file.
 */
class MainActivity : AppCompatActivity(), LifecycleOwner {

    private val audioProcessorExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mediaCaptureExecutor: ExecutorService = Executors.newFixedThreadPool(2)

    private lateinit var cameraLayout: CameraLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Define callback for encoder completion and failure
        val mediaCallback = object : MediaCapture.MediaCaptureCallback {
            override fun onSaved(file: File) {
                // Run callbacks on main thread
                val uiThreadHandler = Handler(Looper.getMainLooper())

                uiThreadHandler.post {
                    // Using an intent action to play final video in system video player
                    val authority = "${this@MainActivity.applicationContext.packageName}.provider"
                    val uri = FileProvider.getUriForFile(this@MainActivity, authority, file)
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        data = uri
                    }

                    val resolveInfoList: List<ResolveInfo> =
                        this@MainActivity.packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)

                    for (resolveInfo in resolveInfoList) {
                        val packageName = resolveInfo.activityInfo.packageName
                        this@MainActivity.grantUriPermission(
                            packageName,
                            uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION
                        )
                    }

                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                    if (intent.resolveActivity(packageManager) != null) {
                        startActivity(intent)
                    }
                }
            }

            override fun onError(e: Exception) {
                Log.d(TAG, "Error encoding in media capture", e)
                finish()
            }
        }

        // Create custom audio source
        val audioSource = if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            AudioProcessorSource(audioProcessorExecutor)
        } else {
            null
        }

        // Creating output file for saving video
        val videoOutputDirectory = cacheDir
        val outputFile = File(videoOutputDirectory, "${UUID.randomUUID()}.mp4")

        setContentView(R.layout.activity_main)

        // This sample uses the CameraLayout helper view that consolidates most common CameraKit use cases
        // into a single class that takes care of runtime permissions and managing CameraKit Session built
        // with default options that can be tweaked using the exposed configure* methods.
        // NOTE: Use of the CameraLayout is encouraged but it is completely optional and depends on the app's
        // requirements and architecture. However, consider working with the CameraKit Session directly to
        // avoid locking your app's design into one that is driven by what's available in the CameraLayout.
        cameraLayout = findViewById<CameraLayout>(R.id.camera_layout).apply {
            // Setting custom audio processor source
            configureSession {
                if (audioSource != null) {
                    audioProcessorSource(audioSource)
                }
            }

            configureLensesCarousel {
                observedGroupIds = linkedSetOf(*LENS_GROUPS)
            }
        }

        cameraLayout.onSessionAvailable { session ->
            cameraLayout.captureButton.onCaptureRequestListener = object : SnapButtonView.OnCaptureRequestListener {
                private var recordingCloseable: Closeable? = null

                override fun onStart(captureType: SnapButtonView.CaptureType) {
                    if (captureType == SnapButtonView.CaptureType.CONTINUOUS) {
                        if (recordingCloseable == null) {
                            // Create capture class that starts encoding upon initialization
                            val outputCloseable: Closeable
                            val captureCloseable =
                                MediaCapture(mediaCallback, outputFile, audioSource, mediaCaptureExecutor).also {
                                    // Get encoding surface and connect it as image processor output
                                    // Retain closeable for disconnecting output when done
                                    outputCloseable = session.processor.connectOutput(
                                        outputFrom(it.surface, ImageProcessor.Output.Purpose.RECORDING)
                                    )
                                }

                            recordingCloseable = Closeable {
                                outputCloseable.close()
                                captureCloseable.close()
                            }
                        }
                    }
                }

                override fun onEnd(captureType: SnapButtonView.CaptureType) {
                    when (captureType) {
                        // Only showing support for video recording in this sample
                        SnapButtonView.CaptureType.CONTINUOUS -> {
                            // Closing stops recording and disconnects surface output
                            recordingCloseable?.close()
                            recordingCloseable = null
                        }
                        else -> { /* no-op */
                        }
                    }
                }
            }
        }

        // Register a handler for the specific CameraLayout exceptions as well as all the other possible errors from
        // the managed CameraKit Session.
        cameraLayout.onError { error ->
            val message = when (error) {
                is CameraLayout.Failure.MissingPermissions -> getString(
                    R.string.required_permissions_not_granted, error.permissions.joinToString(", ")
                )
                is CameraLayout.Failure.DeviceNotSupported -> getString(R.string.camera_kit_unsupported)
                else -> throw error
            }
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onDestroy() {
        audioProcessorExecutor.shutdown()
        mediaCaptureExecutor.shutdown()
        super.onDestroy()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        return if (cameraLayout.dispatchKeyEvent(event)) {
            true
        } else {
            super.dispatchKeyEvent(event)
        }
    }
}
