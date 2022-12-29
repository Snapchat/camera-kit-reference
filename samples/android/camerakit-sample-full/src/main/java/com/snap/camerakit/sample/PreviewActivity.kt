package com.snap.camerakit.sample

import android.app.Activity
import android.app.ActivityOptions
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.LifecycleOwner
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DataSource
import com.bumptech.glide.load.engine.GlideException
import com.bumptech.glide.request.RequestListener
import com.bumptech.glide.request.target.Target
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.source.LoadEventInfo
import com.google.android.exoplayer2.source.MediaLoadData
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.MediaSourceEventListener
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.atomic.AtomicReference

/**
 * Activity to preview and export image and video media presented in a layout that is familiar to Snapchat app users.
 * Video media is provided using ExoPlayer library video player with no user visible controls, while image media is
 * loaded using Glide library. In order to make transitions from other activities to preview feel seamless, we utilize
 * animation-less window transition which waits till preview media is loaded while any activity that starts
 * [PreviewActivity] is still visible.
 */
class PreviewActivity : AppCompatActivity(), LifecycleOwner {

    companion object {

        private const val BUNDLE_ARG_PLAYER_WINDOW_INDEX = "player_window_index"
        private const val BUNDLE_ARG_PLAYER_POSITION = "camera_facing_front"
        private const val BUNDLE_ARG_EXPORTED_MEDIA_URI = "exported_media_uri"

        @JvmStatic
        fun startUsing(
            activity: Activity,
            sharedTransitionView: View,
            file: File,
            mimeType: String
        ) {
            activity.runOnUiThread {
                val options = ActivityOptions.makeSceneTransitionAnimation(
                    activity, sharedTransitionView, activity.getString(R.string.transition_shared_dummy)
                )
                activity.application.startActivity(
                    Intent(activity, PreviewActivity::class.java)
                        .setAction(Intent.ACTION_VIEW)
                        .setDataAndType(Uri.fromFile(file), mimeType)
                        // Using this flag + application to launch new activity to avoid a bug (Android?)
                        // where multiple, rapid startActivity calls mess up the calling Activity (MainActivity)
                        // enter transition (it never finishes) when navigating back from this PreviewActivity.
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    options.toBundle()
                )
            }
        }
    }

    private val singleThreadExecutor = Executors.newSingleThreadExecutor()
    private val mediaExportTask = AtomicReference<Future<*>>()

    private lateinit var videoPreview: PlayerView
    private lateinit var imagePreview: ImageView
    private lateinit var mediaUri: Uri
    private lateinit var mediaFile: File
    private lateinit var mediaMimeType: String

    private var player: ExoPlayer? = null
    private var playerWindowIndex: Int = 0
    private var playerPosition: Long = 0L
    private var exportedMediaUri: Uri? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val type = intent.type
        if (intent.action == Intent.ACTION_VIEW && type != null) {
            intent.data?.let {
                mediaUri = it
                mediaFile = File(it.path!!)
                mediaMimeType = type

                savedInstanceState?.let { state ->
                    playerWindowIndex = state.getInt(BUNDLE_ARG_PLAYER_WINDOW_INDEX, 0)
                    playerPosition = state.getLong(BUNDLE_ARG_PLAYER_POSITION, 0L)
                    exportedMediaUri = state.getString(BUNDLE_ARG_EXPORTED_MEDIA_URI)?.let(Uri::parse)
                }

                postponeEnterTransition()
                setContentView(R.layout.activity_preview)

                videoPreview = findViewById(R.id.video_preview)
                imagePreview = findViewById(R.id.image_preview)

                findViewById<View>(R.id.exit_button).setOnClickListener {
                    onBackPressed()
                }
                findViewById<View>(R.id.export_button).setOnClickListener { view ->
                    view.isEnabled = false
                    mediaExportTask.getAndSet(
                        singleThreadExecutor.submit {
                            exportedMediaUri = if (exportedMediaUri != null) {
                                exportedMediaUri
                            } else {
                                generateContentUri(mediaFile)
                            }?.also { uri ->
                                shareExternally(uri, mediaMimeType)
                            }
                            view.post {
                                view.isEnabled = true
                            }
                        }
                    )?.cancel(true)
                }
            } ?: finish()
        } else {
            finish()
        }
    }

    private fun setupMediaIfNeeded() {
        if (player == null && mediaMimeType == MIME_TYPE_VIDEO_MP4) {
            val exoPlayer = ExoPlayer.Builder(this)
                .build()

            videoPreview.player = exoPlayer

            val dataSourceFactory = DefaultDataSourceFactory(this, "camera-kit-sample")
            val mediaSource = ProgressiveMediaSource.Factory(dataSourceFactory)
                .createMediaSource(mediaUri)
            val mainHandler = Handler(Looper.getMainLooper())
            mediaSource.addEventListener(
                mainHandler,
                object : MediaSourceEventListener {

                    override fun onLoadCompleted(
                        windowIndex: Int,
                        mediaPeriodId: MediaSource.MediaPeriodId?,
                        loadEventInfo: LoadEventInfo,
                        mediaLoadData: MediaLoadData
                    ) {
                        mediaSource.removeEventListener(this)
                        startPostponedEnterTransition()
                    }

                    override fun onLoadError(
                        windowIndex: Int,
                        mediaPeriodId: MediaSource.MediaPeriodId?,
                        loadEventInfo: LoadEventInfo,
                        mediaLoadData: MediaLoadData,
                        error: IOException,
                        wasCanceled: Boolean
                    ) {
                        mediaSource.removeEventListener(this)
                        finish()
                    }
                }
            )

            exoPlayer.addListener(object : Player.Listener {
                override fun onRenderedFirstFrame() {
                    videoPreview.setBackgroundColor(Color.BLACK)
                }
            })

            exoPlayer.repeatMode = Player.REPEAT_MODE_ALL
            exoPlayer.playWhenReady = true
            exoPlayer.seekTo(playerWindowIndex, playerPosition)
            exoPlayer.prepare(mediaSource, false, false)

            player = exoPlayer
        } else if (mediaMimeType == MIME_TYPE_IMAGE_JPEG) {
            imagePreview.post {
                Glide.with(this)
                    .load(mediaUri)
                    .listener(object : RequestListener<Drawable> {

                        override fun onLoadFailed(
                            e: GlideException?,
                            model: Any,
                            target: Target<Drawable>,
                            isFirstResource: Boolean
                        ): Boolean {
                            finish()
                            return false
                        }

                        override fun onResourceReady(
                            resource: Drawable,
                            model: Any,
                            target: Target<Drawable>,
                            dataSource: DataSource,
                            isFirstResource: Boolean
                        ): Boolean {
                            startPostponedEnterTransition()
                            imagePreview.setBackgroundColor(Color.BLACK)
                            return false
                        }
                    })
                    .run {
                        if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
                            fitCenter()
                        } else {
                            centerCrop()
                        }
                    }
                    .into(imagePreview)
            }
        }
    }

    private fun releaseMediaIfNeeded() {
        player?.let {
            playerWindowIndex = it.currentWindowIndex
            playerPosition = it.currentPosition
            it.release()

            videoPreview.player = null
            player = null
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        exportedMediaUri?.let {
            outState.putString(BUNDLE_ARG_EXPORTED_MEDIA_URI, it.toString())
        }
        outState.putInt(BUNDLE_ARG_PLAYER_WINDOW_INDEX, playerWindowIndex)
        outState.putLong(BUNDLE_ARG_PLAYER_POSITION, playerPosition)
        super.onSaveInstanceState(outState)
    }

    override fun onStart() {
        super.onStart()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            setupMediaIfNeeded()
        }
    }

    override fun onResume() {
        super.onResume()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            setupMediaIfNeeded()
        }
    }

    override fun onStop() {
        super.onStop()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            releaseMediaIfNeeded()
        }
    }

    override fun onPause() {
        super.onPause()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            releaseMediaIfNeeded()
        }
    }

    override fun onBackPressed() {
        // Treating back press as user intent to cancel therefore temporary media file is deleted.
        singleThreadExecutor.execute {
            mediaFile.delete()
        }
        super.onBackPressed()
        // Disable slide-out exit animation to match seamless enter transition
        overridePendingTransition(0, 0)
    }

    override fun onDestroy() {
        singleThreadExecutor.shutdown()
        super.onDestroy()
    }
}
