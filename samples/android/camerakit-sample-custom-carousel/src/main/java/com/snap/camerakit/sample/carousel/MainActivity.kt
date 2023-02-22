package com.snap.camerakit.sample.carousel

import android.Manifest
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Bundle
import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.motion.widget.MotionLayout
import androidx.constraintlayout.motion.widget.TransitionAdapter
import androidx.core.view.doOnLayout
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.snap.camerakit.SafeRenderAreaProcessor
import com.snap.camerakit.Session
import com.snap.camerakit.Source
import com.snap.camerakit.common.Consumer
import com.snap.camerakit.invoke
import com.snap.camerakit.lenses.LensesComponent
import com.snap.camerakit.lenses.whenHasSome
import com.snap.camerakit.support.camera.AllowsSnapshotCapture
import com.snap.camerakit.support.camera.AllowsVideoCapture
import com.snap.camerakit.support.camerax.CameraXImageProcessorSource
import com.snap.camerakit.support.permissions.HeadlessFragmentPermissionRequester
import com.snap.camerakit.support.widget.SnapButtonView
import com.snap.camerakit.supported
import java.io.Closeable
import java.io.File
import java.lang.ref.WeakReference
import java.util.concurrent.Executors

private const val TAG = "MainActivity"

/**
 * A simple activity which demonstrates how to use Camera Kit with custom layout for preview as well as custom lenses carousel.
 */
class MainActivity : AppCompatActivity(R.layout.activity_main) {
    private lateinit var cameraKitSession: Session
    private lateinit var imageProcessorSource: CameraXImageProcessorSource

    private lateinit var rootContainer: MotionLayout
    private lateinit var liveCameraContainer: ViewGroup
    private lateinit var previewGestureHandler: View
    private lateinit var selectedLensContainer: ViewGroup
    private lateinit var selectedLensNameView: TextView
    private lateinit var selectedLensIcon: ImageView

    private lateinit var lensesAdapter: LensesAdapter
    private lateinit var lensesListContainer: LinearLayout

    private var isCameraFacingFront = true
    private val processorExecutor = Executors.newSingleThreadExecutor()
    private var permissionRequest: Closeable? = null
    private var videoRecording: Closeable? = null
    private var lensRepositorySubscription: Closeable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Checking if Camera Kit is supported on this device or not.
        if (!supported(this)) {
            Toast.makeText(this, getString(R.string.camera_kit_not_supported), Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        liveCameraContainer = findViewById(R.id.camera_preview_container)
        selectedLensContainer = findViewById(R.id.selected_lens_container)
        selectedLensIcon = findViewById(R.id.selected_lens_icon)
        selectedLensNameView = findViewById(R.id.selected_lens_name)
        rootContainer = findViewById<MotionLayout>(R.id.root_container).apply {
            doOnLayout { view ->
                val dimensionRatio = "W,${view.width}:${view.height}"
                rootContainer.getConstraintSet(R.id.lenses_selector_collapsed).apply {
                    setDimensionRatio(R.id.camera_preview_container, dimensionRatio)
                }
                rootContainer.getConstraintSet(R.id.lenses_selector_expanded).apply {
                    setDimensionRatio(R.id.camera_preview_container, dimensionRatio)
                }
            }
        }
        lensesListContainer = findViewById(R.id.lenses_list_container)

        val tapGestureDetector = GestureDetector(
            this,
            object : GestureDetector.SimpleOnGestureListener() {
                override fun onDoubleTap(event: MotionEvent): Boolean {
                    flipCamera()
                    return super.onDoubleTap(event)
                }

                override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                    rootContainer.transitionToStart()
                    return super.onSingleTapConfirmed(e)
                }
            }
        )

        previewGestureHandler = findViewById<View>(R.id.preview_gesture_handler).apply {
            setOnTouchListener { _, event ->
                tapGestureDetector.onTouchEvent(event)
                when (event.action) {
                    MotionEvent.ACTION_UP -> performClick()
                }
                true
            }
        }

        // App can either use Camera Kit's CameraXImageProcessorSource (which is part of the :support-camerax
        // dependency) or their own input/output and later attach it to the Camera Kit session.
        imageProcessorSource = CameraXImageProcessorSource(
            context = this,
            lifecycleOwner = this,
            executorService = processorExecutor,
            videoOutputDirectory = cacheDir
        )

        // App can either use Camera Kit's CameraLayout for easy integration or define a custom
        // layout like in this case. For custom layout, app needs to just attach the view to Camera
        // Kit Session. Also, App Id and API token can be passed dynamically through Session APIs like in this
        // case (recommended) or it can be hardcoded in AndroidManifest.xml file.
        cameraKitSession = Session(this) {
            apiToken(BuildConfig.CAMERA_KIT_API_TOKEN)
            applicationId(BuildConfig.APPLICATION_ID)
            imageProcessorSource(imageProcessorSource)
            attachTo(findViewById(R.id.camera_kit_stub))
            safeRenderAreaProcessorSource(SafeRenderAreaProcessorSource(this@MainActivity))
            configureLenses {
                // When CameraKit is configured to manage its own views by providing a view stub,
                // lenses touch handling might consume all events due to the fact that it needs to perform gesture
                // detection internally. If application needs to handle gestures on top of it then LensesComponent
                // provides a way to dispatch all touch events unhandled by active lens back.
                it.dispatchTouchEventsTo(previewGestureHandler)
            }
        }

        getOsPermissions()

        // This block demonstrates how to query the repository to get all Lenses from a Camera Kit
        // group. You can query from multiple groups or pre-fetch all Lenses before even user opens
        // the Camera Kit integration. Camera Kit APIs are thread safe - so it's safe to call them
        // from here.
        lensRepositorySubscription = cameraKitSession.lenses.repository.observe(
            LensesComponent.Repository.QueryCriteria.Available(setOf(BuildConfig.LENS_GROUP_ID_TEST))
        ) { result ->
            result.whenHasSome { lenses ->
                runOnUiThread {
                    lensesAdapter.submitList(lenses)
                }
                applyLens(lenses.first())
            }
        }

        findViewById<SnapButtonView>(R.id.capture_button).apply {
            addPreviewFeature()
        }

        findViewById<ImageButton>(R.id.camera_flip_button).apply {
            setOnClickListener {
                flipCamera()
            }
        }

        findViewById<ImageButton>(R.id.button_cancel_effect).apply {
            setOnClickListener {
                clearLenses()
            }
        }

        findViewById<RecyclerView>(R.id.lenses_list).apply {
            lensesAdapter = LensesAdapter { selectedLens ->
                applyLens(selectedLens)
            }
            layoutManager = GridLayoutManager(this@MainActivity, 3)
            adapter = lensesAdapter
        }
    }

    private fun applyLens(lens: LensesComponent.Lens) {
        val usingCorrectCamera =
            isCameraFacingFront.xor(lens.facingPreference != LensesComponent.Lens.Facing.FRONT)
        if (!usingCorrectCamera) flipCamera()
        cameraKitSession.lenses.processor.apply(lens) { success ->
            if (success) {
                runOnUiThread {
                    lensesAdapter.select(lens)
                    selectedLensContainer
                        .animate()
                        .alpha(1.0f)
                        .withStartAction {
                            selectedLensContainer.visibility = View.VISIBLE
                        }
                        .start()
                    selectedLensNameView.text = lens.name
                    Glide.with(selectedLensIcon).load(
                        lens.icons.find {
                            it is LensesComponent.Lens.Media.Image.Webp
                        }?.uri
                    ).into(selectedLensIcon)
                }
            }
        }
    }

    private fun clearLenses() {
        cameraKitSession.lenses.processor.clear { success ->
            if (success) {
                runOnUiThread {
                    lensesAdapter.deselect()
                    selectedLensContainer
                        .animate()
                        .alpha(0.0f)
                        .withEndAction {
                            selectedLensContainer.visibility = View.INVISIBLE
                        }
                        .start()
                }
            }
        }
    }

    private fun flipCamera() {
        runOnUiThread {
            imageProcessorSource.startPreview(!isCameraFacingFront)
            isCameraFacingFront = !isCameraFacingFront
        }
    }

    override fun onDestroy() {
        permissionRequest?.close()
        lensRepositorySubscription?.close()
        cameraKitSession.close()
        processorExecutor.shutdown()
        super.onDestroy()
    }

    private fun getOsPermissions() {
        val requiredPermissions = arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
        // HeadlessFragmentPermissionRequester is part of the :support-permissions, which allows you to easily handle
        // permission requests
        permissionRequest =
            HeadlessFragmentPermissionRequester(this, requiredPermissions.toSet()) { permissions ->
                if (requiredPermissions.mapNotNull(permissions::get).all { it }) {
                    imageProcessorSource.startPreview(isCameraFacingFront)
                } else {
                    Log.e(TAG, "Permissions denied: $permissions")
                }
            }
    }

    // SnapButtonView is part of the :support-snap-button, which allows you to easily set listeners when user takes
    // photo or a video
    private fun SnapButtonView.addPreviewFeature() {
        val onImageTaken: (Bitmap) -> Unit = { bitmap ->
            runOnUiThread {
                PreviewActivity.startUsing(
                    this@MainActivity, rootContainer, this@MainActivity.cacheJpegOf(bitmap), MIME_TYPE_IMAGE_JPEG
                )
            }
        }
        val onVideoTaken: (File) -> Unit = { video ->
            PreviewActivity.startUsing(
                this@MainActivity, rootContainer, video, MIME_TYPE_VIDEO_MP4
            )
        }

        onCaptureRequestListener = object : SnapButtonView.OnCaptureRequestListener {
            override fun onStart(captureType: SnapButtonView.CaptureType) {
                if (captureType == SnapButtonView.CaptureType.CONTINUOUS) {
                    if (videoRecording == null) {
                        videoRecording = (imageProcessorSource as? AllowsVideoCapture)?.takeVideo(onVideoTaken)
                    }
                }
            }

            override fun onEnd(captureType: SnapButtonView.CaptureType) {
                when (captureType) {
                    SnapButtonView.CaptureType.CONTINUOUS -> {
                        videoRecording?.close()
                        videoRecording = null
                    }
                    SnapButtonView.CaptureType.SNAPSHOT -> {
                        (imageProcessorSource as? AllowsSnapshotCapture)?.takeSnapshot(onImageTaken)
                    }
                }
            }
        }
    }

    /**
     * Simple implementation of a [Source] for a [SafeRenderAreaProcessor] that calculates a safe render area [Rect]
     * that is between the top and selected lens container present in the [MainActivity].
     */
    private class SafeRenderAreaProcessorSource(mainActivity: MainActivity) : Source<SafeRenderAreaProcessor> {

        private val mainActivityReference = WeakReference(mainActivity)

        override fun attach(processor: SafeRenderAreaProcessor): Closeable {

            return processor.connectInput(object : SafeRenderAreaProcessor.Input {

                override fun subscribeTo(onSafeRenderAreaAvailable: Consumer<Rect>): Closeable {
                    val activity = mainActivityReference.get()
                    if (activity == null) {
                        return Closeable { }
                    } else {
                        fun updateSafeRenderRegionIfNecessary() {
                            val safeRenderRect = Rect()
                            if (activity.liveCameraContainer.getGlobalVisibleRect(safeRenderRect)) {
                                val tmpRect = Rect()
                                activity.window.decorView.getWindowVisibleDisplayFrame(tmpRect)
                                val statusBarHeight = tmpRect.top
                                // Make the zone's top to start below the status bar.
                                safeRenderRect.top = statusBarHeight
                                // Make the zone's bottom to start above selected lens container,
                                // anything under or below it should not be considered safe to render to.
                                if (activity.selectedLensContainer.getGlobalVisibleRect(tmpRect)) {
                                    safeRenderRect.bottom = tmpRect.top - statusBarHeight
                                }
                                onSafeRenderAreaAvailable.accept(safeRenderRect)
                            }
                        }
                        // The processor might subscribe to the input when views are laid out already so we can attempt
                        // to calculate the safe render area already
                        activity.runOnUiThread {
                            updateSafeRenderRegionIfNecessary()
                        }
                        // Otherwise we start listening for layout changes to update the safe render rect continuously
                        val onLayoutChangeListener =
                            View.OnLayoutChangeListener {
                                _, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
                                if (left != oldLeft || top != oldTop || right != oldRight || bottom != oldBottom) {
                                    updateSafeRenderRegionIfNecessary()
                                }
                            }

                        val transitionListener = object : TransitionAdapter() {

                            override fun onTransitionChange(
                                motionLayout: MotionLayout?,
                                startId: Int,
                                endId: Int,
                                progress: Float
                            ) {
                                updateSafeRenderRegionIfNecessary()
                            }
                        }

                        activity.rootContainer.addOnLayoutChangeListener(onLayoutChangeListener)
                        activity.rootContainer.addTransitionListener(transitionListener)
                        return Closeable {
                            activity.rootContainer.removeOnLayoutChangeListener(onLayoutChangeListener)
                            activity.rootContainer.removeTransitionListener(transitionListener)
                        }
                    }
                }
            })
        }
    }
}
