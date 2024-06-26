package com.snap.camerakit.sample.basic

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.snap.camerakit.Session
import com.snap.camerakit.invoke
import com.snap.camerakit.lenses.LensesComponent
import com.snap.camerakit.lenses.whenHasFirst
import com.snap.camerakit.support.camerax.CameraXImageProcessorSource
import com.snap.camerakit.supported
import java.io.Closeable

/**
 * A bare minimum Camera Kit app which simply applies 1 Lens in full screen. You should add error handling and UI
 * components as needed.
 */
class MainActivity : AppCompatActivity(R.layout.activity_main) {

    private lateinit var cameraKitSession: Session
    private lateinit var imageProcessorSource: CameraXImageProcessorSource
    private var permissionRequest: Closeable? = null

    // Initialize a permission request launcher
    private val requestPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
            if (isGranted) {
                startPreview()
            } else {
                // Explain to the user that Camera Kit is unavailable because the
                // requested camera permission is denied by the user, then attempt retry.
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Checking if Camera Kit is supported on this device or not.
        if (!supported(this)) {
            Toast.makeText(this, getString(R.string.camera_kit_not_supported), Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        imageProcessorSource = CameraXImageProcessorSource(
            context = this, lifecycleOwner = this
        )

        // If camera permission is granted, then start the preview
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            startPreview()
        } else {
            requestPermissionLauncher.launch(Manifest.permission.CAMERA)
        }

        cameraKitSession = Session(context = this) {
            apiToken(BuildConfig.CAMERA_KIT_API_TOKEN)
            imageProcessorSource(imageProcessorSource)
            attachTo(findViewById(R.id.camera_kit_stub))
        }.apply {
            lenses.repository.observe(
                LensesComponent.Repository.QueryCriteria.Available(BuildConfig.LENS_GROUP_ID_TEST)
            ) { result ->
                result.whenHasFirst { firstLens ->
                    // applying the first Lens here but you can choose any other Lens from the result to be applied
                    lenses.processor.apply(firstLens)
                }
            }
        }
    }

    private fun startPreview() {
        // starting preview with world facing camera
        imageProcessorSource.startPreview(false)
    }

    override fun onDestroy() {
        permissionRequest?.close()
        cameraKitSession.close()
        super.onDestroy()
    }
}
