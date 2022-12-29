package com.snap.camerakit.sample

import android.graphics.BitmapFactory
import android.graphics.RectF
import android.graphics.SurfaceTexture
import android.os.Bundle
import android.util.Size
import android.view.Choreographer
import android.view.Surface
import android.view.TextureView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.LifecycleOwner
import com.snap.camerakit.Session
import com.snap.camerakit.connectOutput
import com.snap.camerakit.inputFrom
import com.snap.camerakit.invoke
import com.snap.camerakit.lenses.LENS_GROUP_ID_BUNDLED
import com.snap.camerakit.lenses.LensesComponent
import com.snap.camerakit.lenses.whenHasFirst
import java.io.Closeable
import kotlin.math.min

private const val DEFAULT_IMAGE_INPUT_FIELD_OF_VIEW = 50F

/**
 * A simple activity that demonstrates how to create a custom [com.snap.camerakit.ImageProcessor.Input] based on a
 * [SurfaceTexture] which is filled with contents from an image. In reality, CameraKit expects an input source to be a
 * proper realtime camera stream however the contrived use of an image here is provided solely as a simplified example.
 */
class MainActivity : AppCompatActivity(), LifecycleOwner {

    private lateinit var session: Session
    private lateinit var inputSurface: Surface
    private lateinit var inputSurfaceUpdateCallback: Choreographer.FrameCallback

    private val choreographer = Choreographer.getInstance()
    private val closeOnDestroy = mutableListOf<Closeable>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_main)

        // Basic CameraKit Session use case to apply a first bundled lens that is available.
        session = Session(this).apply {
            lenses.repository.get(LensesComponent.Repository.QueryCriteria.Available(LENS_GROUP_ID_BUNDLED)) { result ->
                result.whenHasFirst { lens ->
                    lenses.processor.apply(lens)
                }
            }
        }

        // Example setup of an input that is backed by a SurfaceTexture.
        val inputTextureSize = Size(1440, 2560)
        val inputSurfaceTexture = SurfaceTexture(0).apply {
            setDefaultBufferSize(inputTextureSize.width, inputTextureSize.height)
            // It is a must to always detach the texture from a GL context before connecting the texture as an input
            // to CameraKit where the texture gets attached to an internal GL context.
            detachFromGLContext()
        }
        val input = inputFrom(
            surfaceTexture = inputSurfaceTexture,
            width = inputTextureSize.width,
            height = inputTextureSize.height,
            facingFront = true,
            rotationDegrees = 0,
            horizontalFieldOfView = DEFAULT_IMAGE_INPUT_FIELD_OF_VIEW,
            verticalFieldOfView = DEFAULT_IMAGE_INPUT_FIELD_OF_VIEW
        )
        closeOnDestroy.add(session.processor.connectInput(input))

        // To render CameraKit processed input we use a convenience method to connect TextureView as an output.
        val previewTextureView = findViewById<TextureView>(R.id.camerakit_output_preview)
        closeOnDestroy.add(session.processor.connectOutput(previewTextureView))

        // We wrap the SurfaceTexture with a Surface so that we can draw to it via Canvas.
        inputSurface = Surface(inputSurfaceTexture)

        val inputImage = BitmapFactory.decodeResource(resources, R.drawable.woman_face)
        val scale = min(inputTextureSize.width / inputImage.width, inputTextureSize.height / inputImage.height)
        val scaledWith = scale * inputImage.width
        val padding = inputTextureSize.width - scaledWith
        val dstRect = RectF(
            0f,
            0f + padding,
            inputTextureSize.width.toFloat(),
            inputTextureSize.height - padding.toFloat()
        )

        // We post callbacks on Android's Choreographer to simply get a rendering loop going, this could also be
        // done through a handler etc. however it is nice to simply hook into VSYNC events to trigger re-draw.
        inputSurfaceUpdateCallback = object : Choreographer.FrameCallback {
            override fun doFrame(frameTimeNanos: Long) {
                val canvas = inputSurface.lockCanvas(null)
                try {
                    canvas.drawBitmap(inputImage, null, dstRect, null)
                } finally {
                    inputSurface.unlockCanvasAndPost(canvas)
                }
                choreographer.postFrameCallback(this)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        choreographer.postFrameCallback(inputSurfaceUpdateCallback)
    }

    override fun onPause() {
        super.onPause()
        if (::inputSurfaceUpdateCallback.isInitialized) {
            choreographer.removeFrameCallback(inputSurfaceUpdateCallback)
        }
    }

    override fun onDestroy() {
        closeOnDestroy.forEach {
            it.close()
        }
        session.close()
        inputSurface.release()
        super.onDestroy()
    }
}
