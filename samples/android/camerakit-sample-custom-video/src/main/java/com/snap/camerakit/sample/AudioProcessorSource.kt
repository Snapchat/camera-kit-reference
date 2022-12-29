package com.snap.camerakit.sample

import android.Manifest
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import androidx.annotation.RequiresPermission
import com.snap.camerakit.AudioProcessor
import com.snap.camerakit.Source
import com.snap.camerakit.common.Consumer
import com.snap.camerakit.inputFrameFrom
import java.io.Closeable
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicReference

// Audio recording config constants
private const val AUDIO_SAMPLE_RATE_HZ = 44100
private const val AUDIO_SAMPLE_SIZE = 2
private const val AUDIO_CHANNEL_COUNT = 1
private const val AUDIO_BUFFER_SIZE = 2048
private const val AUDIO_CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
private const val AUDIO_RECORDING_FORMAT = AudioFormat.ENCODING_PCM_16BIT

private const val TAG = "AudioProcessorSource"

/**
 * Custom implementation of a [Source] for an [AudioProcessor]
 * Utilizes [AudioRecord] to record microphone audio as an input source
 * and provides it to [MediaCapture] for encoding and muxing with video.
 * This implementation is customizable in configuration or source.
 *
 * @param executorService Thread pool to run audio recording on
 */
internal class AudioProcessorSource(
    private val executorService: ExecutorService = Executors.newSingleThreadExecutor()
) : Source<AudioProcessor>, MediaCapture.AudioSource {

    private val audioProcessor: AtomicReference<AudioProcessor> = AtomicReference()
    private val recordingTask: AtomicReference<Future<*>> = AtomicReference()
    private var inputConsumer: Consumer<ByteArray> = Consumers.empty()

    override fun attach(processor: AudioProcessor): Closeable {
        audioProcessor.set(processor)

        return Closeable {
            audioProcessor.set(null)
        }
    }

    override fun subscribe(consumer: Consumer<ByteArray>): Closeable {
        inputConsumer = consumer
        val recordingCloseable = startRecording()

        return Closeable {
            recordingCloseable.close()
            inputConsumer = Consumers.empty()
        }
    }

    @RequiresPermission(Manifest.permission.RECORD_AUDIO, conditional = true)
    private fun startRecording(): Closeable {
        Log.d(TAG, "Start audio recording")

        try {
            recordingTask.getAndSet(
                executorService.submit {
                    var audioRecorder: AudioRecord? = null

                    try {
                        audioRecorder = AudioRecord(
                            MediaRecorder.AudioSource.CAMCORDER,
                            AUDIO_SAMPLE_RATE_HZ,
                            AUDIO_CHANNEL_CONFIG,
                            AUDIO_RECORDING_FORMAT,
                            AUDIO_BUFFER_SIZE
                        )

                        if (audioRecorder.state == AudioRecord.STATE_UNINITIALIZED) {
                            audioRecorder.release()
                            throw IllegalStateException("Audio recorder failed to initialize properly")
                        }

                        audioRecorder.startRecording()

                        val buffer = ByteArray(AUDIO_BUFFER_SIZE)
                        val audioInput = AudioInput(
                            AUDIO_CHANNEL_COUNT,
                            AUDIO_SAMPLE_RATE_HZ,
                            AUDIO_BUFFER_SIZE,
                            AUDIO_SAMPLE_SIZE
                        )

                        var inputCloseable: Closeable? = null
                        while (!Thread.currentThread().isInterrupted) {
                            if (inputCloseable == null && audioProcessor.get() != null) {
                                inputCloseable = audioProcessor.get().connectInput(audioInput)
                            }

                            val result = audioRecorder.read(buffer, 0, AUDIO_BUFFER_SIZE)
                            when {
                                result > 0 -> {
                                    audioInput.processFrame(buffer)
                                    inputConsumer.accept(buffer)
                                }
                                result < 0 -> {
                                    val error = when (result) {
                                        AudioRecord.ERROR -> "ERROR"
                                        AudioRecord.ERROR_BAD_VALUE -> "ERROR_BAD_VALUE"
                                        AudioRecord.ERROR_DEAD_OBJECT -> "ERROR_DEAD_OBJECT"
                                        AudioRecord.ERROR_INVALID_OPERATION -> "ERROR_INVALID_OPERATION"
                                        else -> "Unknown error code ($result)"
                                    }

                                    Log.e(TAG, "Failed to read audio buffer: $error")
                                    Thread.currentThread().interrupt()
                                }
                                else -> {
                                    Log.d(TAG, "Audio recorder read 0 bytes, EOF reached")
                                    Thread.currentThread().interrupt()
                                }
                            }
                        }

                        inputCloseable?.close()

                        try {
                            audioRecorder.stop()
                        } catch (e: IllegalStateException) {
                            Log.e(TAG, "Failed to stop audio recorder")
                        }
                    } finally {
                        audioRecorder?.release()
                    }
                }
            )?.cancel(true)
        } catch (e: RejectedExecutionException) {
            Log.e(TAG, "Could not start recording task due to ExecutorService shutdown", e)
        }

        return Closeable {
            recordingTask.getAndSet(null)?.cancel(true)
        }
    }

    private class AudioInput(
        override val channels: Int,
        override val sampleRate: Int,
        override val bufferSize: Int,
        private val sampleSize: Int
    ) : AudioProcessor.Input {

        private var onFrameAvailable: Consumer<AudioProcessor.Input.Frame> = Consumers.empty()

        override fun subscribeTo(onFrameAvailable: Consumer<AudioProcessor.Input.Frame>): Closeable {
            this.onFrameAvailable = onFrameAvailable

            return Closeable {
                this.onFrameAvailable = Consumers.empty()
            }
        }

        /**
         * Process audio data to be modified with lens audio if selected lens augments voice/audio
         *
         * @param buffer ByteBuffer to be processed
         */
        fun processFrame(buffer: ByteArray) {
            onFrameAvailable.let {
                val sampleCount = buffer.size / sampleSize
                // ByteArray is modified in place
                it.accept(inputFrameFrom(buffer, sampleCount))
            }
        }
    }
}
