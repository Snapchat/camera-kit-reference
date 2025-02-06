package com.example.camerakit.sample.compose

import android.Manifest
import android.os.Bundle
import android.view.LayoutInflater
import android.view.ViewStub
import android.widget.Toast
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.viewinterop.AndroidView
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.accompanist.permissions.shouldShowRationale
import com.snap.camerakit.Session
import com.snap.camerakit.invoke
import com.snap.camerakit.lenses.LensesComponent
import com.snap.camerakit.lenses.whenHasFirst
import com.snap.camerakit.support.camerax.CameraXImageProcessorSource
import com.snap.camerakit.supported

/**
 * A bare minimum Camera Kit app, using Jetpack Compose, which simply applies 1 Lens in full screen. You should add error handling and UI
 * components as needed.
 */
class MainActivity : AppCompatActivity() {

    private var cameraKitSession: Session? = null
    private lateinit var imageProcessorSource: CameraXImageProcessorSource
    companion object {
        const val LENS_GROUP_ID = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
        const val LENS_ID = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        if (!supported(this)) {
            Toast.makeText(this, R.string.camera_kit_not_supported, Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        imageProcessorSource = CameraXImageProcessorSource(context = this, lifecycleOwner = this)

        setContent {
            CameraPreview(onCameraPermissionDenied = {
                Toast.makeText(this, R.string.camera_permission_not_granted, Toast.LENGTH_SHORT).show()
                finish()
            })
        }
    }

    @OptIn(ExperimentalPermissionsApi::class)
    @Composable
    fun CameraPreview(onCameraPermissionDenied: () -> Unit) {
        val cameraPermissionState = rememberPermissionState(
            Manifest.permission.CAMERA
        )

        if (!cameraPermissionState.status.isGranted) {
            if (cameraPermissionState.status.shouldShowRationale) {
                onCameraPermissionDenied()
            } else {
                LaunchedEffect(Unit) {
                    cameraPermissionState.launchPermissionRequest()
                }
            }
        } else {
            imageProcessorSource.startPreview(false)

            AndroidView(
                factory = { ctx ->
                    LayoutInflater.from(ctx).inflate(R.layout.camera_layout, null).apply {
                        val viewStub = findViewById<ViewStub>(R.id.camera_kit_stub)

                        cameraKitSession = Session(context = ctx) {
                            imageProcessorSource(imageProcessorSource)
                            attachTo(viewStub)
                        }.apply {
                            lenses.repository.observe(
                                LensesComponent.Repository.QueryCriteria.ById(LENS_ID, LENS_GROUP_ID)
                            ) { result ->
                                result.whenHasFirst { requestedLens ->
                                    lenses.processor.apply(requestedLens)
                                }
                            }
                        }
                    }
                }
            )
        }
    }

    override fun onDestroy() {
        cameraKitSession?.close()
        super.onDestroy()
    }
}
