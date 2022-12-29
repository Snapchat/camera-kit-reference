package com.snap.camerakit.sample

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import android.view.Surface
import androidx.annotation.GuardedBy
import com.snap.camerakit.common.Consumer
import java.io.Closeable
import java.io.File
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.ceil

// Mime types for video/audio encoding
const val MIME_TYPE_VIDEO_AVC = "video/avc"
const val MIME_TYPE_AUDIO_MP4A = "audio/mp4a-latm"

// Video encoder configuration constants
private const val DEQUE_TIMEOUT_USEC_VIDEO = 10000L
private const val VIDEO_FRAME_RATE = 30
private const val VIDEO_IFRAME_INTERVAL = 1
private const val VIDEO_BITS_PER_PIXEL = 0.15
private const val VIDEO_WIDTH = 1080
private const val VIDEO_HEIGHT = 1920

// Audio encoder configuration constants
private const val DEQUE_TIMEOUT_USEC_AUDIO_INPUT = -1L
private const val DEQUE_TIMEOUT_USEC_AUDIO_OUTPUT = 0L
private const val AUDIO_SAMPLE_RATE_HZ = 44100
private const val AUDIO_BITRATE = 128 * 1024
private const val AUDIO_CHANNEL_COUNT = 1

private const val TAG = "MediaCapture"

private val EMPTY_CLOSEABLE = Closeable { }

/**
 * Class used to encode and mux audio + video into an MP4 file output
 * Uses Android's media framework - [MediaCodec] and [MediaMuxer] for encoding and muxing
 * Configuration of audio and video codecs is open to customization
 *
 * Implementation is similar to Android's CameraX VideoCapture
 *
 * @param captureCallback Callback for sending updates on completion or failure
 * @param file Output file to save encoding to
 * @param audioSource Source if audio, if any audio is being used for recording. Null if no audio is used
 * @param executorService Thread pool for audio and video encoding. Each will be on separate threads
 */
internal class MediaCapture(
    private val captureCallback: MediaCaptureCallback,
    private val file: File,
    private val audioSource: AudioSource? = null,
    private val executorService: ExecutorService = Executors.newFixedThreadPool(2)
) : Closeable {

    // Surface used as input for video encoder
    val surface: Surface

    private val endOfVideoStreamSignal: AtomicBoolean = AtomicBoolean(true)
    private val endOfAudioVideoSignal: AtomicBoolean = AtomicBoolean(true)

    private val audioEncoder: MediaCodec
    private val videoEncoder: MediaCodec

    private val muxerLock = Object()

    @GuardedBy("muxerLock")
    private lateinit var muxer: MediaMuxer

    private val recordingCloseable: Closeable

    init {
        Log.d(TAG, "Setup audio encoder")

        try {
            audioEncoder = MediaCodec.createEncoderByType(MIME_TYPE_AUDIO_MP4A).apply {
                reset()

                val mediaFormat =
                    MediaFormat.createAudioFormat(MIME_TYPE_AUDIO_MP4A, AUDIO_SAMPLE_RATE_HZ, AUDIO_CHANNEL_COUNT)
                mediaFormat.setInteger(MediaFormat.KEY_BIT_RATE, AUDIO_BITRATE)

                configure(mediaFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            }
        } catch (e: IOException) {
            throw IllegalStateException("Unable to create audio encoder: ${e.cause}")
        }

        Log.d(TAG, "Setup video encoder")

        try {
            videoEncoder = MediaCodec.createEncoderByType(MIME_TYPE_VIDEO_AVC).apply {
                reset()

                val mediaFormat = MediaFormat.createVideoFormat(MIME_TYPE_VIDEO_AVC, VIDEO_WIDTH, VIDEO_HEIGHT)
                val bitRate = ceil(VIDEO_WIDTH * VIDEO_HEIGHT * VIDEO_FRAME_RATE * VIDEO_BITS_PER_PIXEL).toInt()
                mediaFormat.setInteger(
                    MediaFormat.KEY_COLOR_FORMAT,
                    MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
                )
                mediaFormat.setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
                mediaFormat.setInteger(MediaFormat.KEY_FRAME_RATE, VIDEO_FRAME_RATE)
                mediaFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, VIDEO_IFRAME_INTERVAL)

                configure(mediaFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                surface = createInputSurface()
            }
        } catch (e: IOException) {
            throw IllegalStateException("Unable to create video encoder: ${e.cause}")
        }

        recordingCloseable = startRecording()
    }

    override fun close() {
        recordingCloseable.close()
    }

    private fun startRecording(): Closeable {
        Log.d(TAG, "Start recording")

        val isAudioProvided = audioSource != null
        val audioTrackIndex = AtomicInteger(-1)
        val videoTrackIndex = AtomicInteger(-1)
        val muxerStarted = AtomicBoolean(false)

        if (!endOfAudioVideoSignal.get()) {
            captureCallback.onError(IllegalStateException("Video is still in recording"))
            return EMPTY_CLOSEABLE
        }

        endOfVideoStreamSignal.set(false)
        endOfAudioVideoSignal.set(false)

        val audioEncodingTask = AtomicReference<Future<*>>()

        try {
            Log.d(TAG, "Starting video encoder")
            videoEncoder.start()

            if (isAudioProvided) {
                Log.d(TAG, "Starting audio encoder")
                audioEncoder.start()
            }
        } catch (e: IllegalStateException) {
            captureCallback.onError(e)
            return EMPTY_CLOSEABLE
        }

        try {
            synchronized(muxerLock) {
                Log.d(TAG, "Creating muxer")
                muxer = MediaMuxer(file.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            }
        } catch (e: IOException) {
            captureCallback.onError(e)
            return EMPTY_CLOSEABLE
        }

        // If audio source is provided, subscribe to audio source to receive audio frames
        // Store closeable to disconnect and stop receiving frames later
        val inputCloseable = audioSource?.subscribe { byteArray ->
            // Creates an input buffer and enqueues it for the audio encoder to use
            val inputBufferIdx = audioEncoder.dequeueInputBuffer(DEQUE_TIMEOUT_USEC_AUDIO_INPUT)
            if (inputBufferIdx >= 0) {
                val buffer = audioEncoder.getInputBuffer(inputBufferIdx)
                if (buffer != null) {
                    buffer.clear()
                    // Input buffer and processed byte array data should be same size
                    // In this sample, its 2048B (2MB)
                    // Copy processed byte array data into cleared input buffer for audio encoder
                    buffer.put(byteArray)
                    val flags = if (!Thread.currentThread().isInterrupted) 0 else MediaCodec.BUFFER_FLAG_END_OF_STREAM
                    audioEncoder.queueInputBuffer(
                        inputBufferIdx,
                        0,
                        byteArray.size,
                        (System.nanoTime() / 1000),
                        flags
                    )
                }
            }
        }

        try {
            if (isAudioProvided) {
                audioEncodingTask.getAndSet(
                    executorService.submit {
                        Log.d(TAG, "Encoding audio")

                        var endOfStream = false
                        var lastTimestamp = 0L
                        val bufferInfo = MediaCodec.BufferInfo()

                        while (!endOfStream && !Thread.currentThread().isInterrupted) {
                            when (
                                val outputBufferIdx =
                                    audioEncoder.dequeueOutputBuffer(bufferInfo, DEQUE_TIMEOUT_USEC_AUDIO_OUTPUT)
                            ) {
                                MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                                    synchronized(muxerLock) {
                                        audioTrackIndex.set(muxer.addTrack(audioEncoder.outputFormat))
                                        Log.d(TAG, "Added audio track to muxer. Track: ${audioTrackIndex.get()}")
                                    }

                                    if ((isAudioProvided && audioTrackIndex.get() >= 0 && videoTrackIndex.get() >= 0) ||
                                        (!isAudioProvided && videoTrackIndex.get() >= 0)
                                    ) {
                                        Log.d(TAG, "Starting muxer - encodeAudio")
                                        muxerStarted.set(true)
                                        muxer.start()
                                    }
                                }
                                MediaCodec.INFO_TRY_AGAIN_LATER -> {
                                    // Timed out. Wait until next attempt to deque
                                    /* no-op */
                                }
                                else -> {
                                    if (bufferInfo.presentationTimeUs > lastTimestamp) {
                                        endOfStream = writeAudioEncodedBuffer(
                                            outputBufferIdx,
                                            bufferInfo,
                                            audioTrackIndex.get(),
                                            muxerStarted.get()
                                        )
                                        lastTimestamp = bufferInfo.presentationTimeUs
                                    } else {
                                        Log.d(
                                            TAG,
                                            "Dropping out of order frame. " +
                                                "Current frame timestamp: ${bufferInfo.presentationTimeUs}, " +
                                                "last frame timestamp: $lastTimestamp"
                                        )
                                        audioEncoder.releaseOutputBuffer(outputBufferIdx, false)
                                    }
                                }
                            }
                        }

                        try {
                            Log.d(TAG, "Stopping audio encoder")
                            audioEncoder.stop()
                        } catch (e: IllegalStateException) {
                            captureCallback.onError(e)
                        }

                        endOfVideoStreamSignal.set(true)
                    }
                )?.cancel(true)
            }

            executorService.execute {
                Log.d(TAG, "Encoding video")

                var errorOccurred = false
                var endOfStream = false

                try {
                    val bufferInfo = MediaCodec.BufferInfo()

                    while (!endOfStream && !errorOccurred) {
                        if (endOfVideoStreamSignal.get()) {
                            Log.d(TAG, "End of video stream signaled")
                            videoEncoder.signalEndOfInputStream()
                            endOfVideoStreamSignal.set(false)
                        }

                        when (
                            val outputBufferIdx =
                                videoEncoder.dequeueOutputBuffer(bufferInfo, DEQUE_TIMEOUT_USEC_VIDEO)
                        ) {
                            MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                                if (muxerStarted.get()) {
                                    captureCallback.onError(
                                        IllegalStateException(
                                            "Unexpected change in video encoding format"
                                        )
                                    )
                                    errorOccurred = true
                                }

                                synchronized(muxerLock) {
                                    videoTrackIndex.set(muxer.addTrack(videoEncoder.outputFormat))
                                    Log.d(TAG, "Added video track to muxer. Track: $videoTrackIndex")
                                }

                                if ((isAudioProvided && audioTrackIndex.get() >= 0 && videoTrackIndex.get() >= 0) ||
                                    (!isAudioProvided && videoTrackIndex.get() >= 0)
                                ) {
                                    Log.d(TAG, "Starting muxer - encodeVideo")
                                    muxerStarted.set(true)
                                    muxer.start()
                                }
                            }
                            MediaCodec.INFO_TRY_AGAIN_LATER -> {
                                // Timed out. Wait until next attempt to deque
                                /* no-op */
                            }
                            else -> {
                                endOfStream = writeVideoEncodedBuffer(
                                    outputBufferIdx,
                                    bufferInfo,
                                    videoTrackIndex.get(),
                                    muxerStarted.get()
                                )
                            }
                        }
                    }

                    try {
                        Log.d(TAG, "Stopping video encoder")
                        videoEncoder.stop()
                    } catch (e: IllegalStateException) {
                        captureCallback.onError(e)
                        errorOccurred = true
                    }

                    try {
                        synchronized(muxerLock) {
                            if (muxerStarted.get()) {
                                Log.d(TAG, "Stopping muxer")
                                muxer.stop()
                            }
                            Log.d(TAG, "Releasing muxer")
                            muxer.release()
                        }
                    } catch (e: IllegalStateException) {
                        captureCallback.onError(e)
                        errorOccurred = true
                    }

                    muxerStarted.set(false)
                    endOfAudioVideoSignal.set(true)
                } finally {
                    Log.d(TAG, "Releasing resources")
                    audioEncoder.release()
                    videoEncoder.release()
                    surface.release()
                }

                if (!errorOccurred) {
                    captureCallback.onSaved(file)
                }
            }
        } catch (e: RejectedExecutionException) {
            Log.e(TAG, "Could not start encoding tasks due to ExecutorService shutdown")
            captureCallback.onError(e)
        }

        // Stop audio/video encoding on close
        return Closeable {
            // Disconnect audio input and stop encoding
            inputCloseable?.close()

            Log.d(TAG, "Stop recording. Signaling end of stream")

            // If audio task is set, cancel it to stop audio encoding, otherwise end video stream
            // After end of audio encoding, end of video encoding will be signalled automatically
            audioEncodingTask.getAndSet(null)?.cancel(true)
                ?: endOfVideoStreamSignal.set(true)
        }
    }

    private fun writeAudioEncodedBuffer(
        bufferIdx: Int,
        bufferInfo: MediaCodec.BufferInfo,
        audioTrackIndex: Int,
        muxerStarted: Boolean
    ): Boolean {
        val outputBuffer = audioEncoder.getOutputBuffer(bufferIdx) ?: return false
        outputBuffer.position(bufferInfo.offset)

        if (muxerStarted &&
            audioTrackIndex >= 0 &&
            bufferInfo.size > 0 &&
            bufferInfo.presentationTimeUs > 0
        ) {
            synchronized(muxerLock) {
                muxer.writeSampleData(audioTrackIndex, outputBuffer, bufferInfo)
            }
        }

        audioEncoder.releaseOutputBuffer(bufferIdx, false)

        return (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0
    }

    private fun writeVideoEncodedBuffer(
        bufferIdx: Int,
        bufferInfo: MediaCodec.BufferInfo,
        videoTrackIndex: Int,
        muxerStarted: Boolean
    ): Boolean {
        if (bufferIdx < 0) {
            return false
        }

        val outputBuffer = videoEncoder.getOutputBuffer(bufferIdx) ?: return false

        if (muxerStarted &&
            videoTrackIndex >= 0 &&
            bufferInfo.size > 0
        ) {
            outputBuffer.position(bufferInfo.offset)
            outputBuffer.limit(bufferInfo.offset + bufferInfo.size)

            synchronized(muxerLock) {
                muxer.writeSampleData(videoTrackIndex, outputBuffer, bufferInfo)
            }
        }

        videoEncoder.releaseOutputBuffer(bufferIdx, false)

        return (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0
    }

    /**
     * Callback for when the media file saved after encoding or if an error occurred during encoding
     */
    interface MediaCaptureCallback {
        /**
         * Called when encoding is finished and media file is ready to be played
         *
         * @param file File where the final result of encoding is saved
         */
        fun onSaved(file: File)

        /**
         * Called if an error occurred during the process of encoding
         *
         * @param e Exception caught during an error
         */
        fun onError(e: Exception)
    }

    /**
     * Audio source that provides buffer data to be consumed and encoded with video
     */
    interface AudioSource {
        /**
         * Subscribes consumer to audio source
         *
         * @param consumer Consumer to process provided audio data
         *
         * @return Closeable to disconnect and stop input
         */
        fun subscribe(consumer: Consumer<ByteArray>): Closeable
    }
}
