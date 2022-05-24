package com.snap.camerakit.sample;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.media.Image;
import android.view.Surface;
import android.view.TextureView;

import androidx.annotation.NonNull;

import com.snap.camerakit.AudioProcessor;
import com.snap.camerakit.AudioProcessors;
import com.snap.camerakit.ImageProcessor;
import com.snap.camerakit.ImageProcessors;
import com.snap.camerakit.Session;
import com.snap.camerakit.Sessions;
import com.snap.camerakit.Source;
import com.snap.camerakit.lenses.LensesComponent;
import com.snap.camerakit.lenses.LensesLaunchData;
import com.snap.camerakit.plugin.Plugin;

import java.io.Closeable;
import java.io.File;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Simple implementation of {@link Plugin} that delegates all calls to the CameraKit SDK.
 */
public final class DefaultPlugin extends Plugin {

    private Context context;

    @NonNull
    @Override
    protected Plugin attach(@NonNull Context context) {
        this.context = context;
        return this;
    }

    @Override
    protected boolean supported() {
        return Sessions.supported(context);
    }

    @NonNull
    @Override
    public Session.Builder newSessionBuilder() {
        return Sessions.newBuilder(context);
    }

    @NonNull
    @Override
    public ImageProcessor.Input imageProcessorInputFrom(
            @NonNull SurfaceTexture surfaceTexture,
            int width,
            int height,
            int rotationDegrees,
            boolean facingFront,
            @NonNull Callable<Float> horizontalFieldOfView,
            @NonNull Callable<Float> verticalFieldOfView
    ) {
        return ImageProcessors.inputFrom(
                surfaceTexture, width, height, rotationDegrees, facingFront, horizontalFieldOfView, verticalFieldOfView
        );
    }

    @NonNull
    @Override
    public ImageProcessor.Output imageProcessorOutputFrom(
            @NonNull SurfaceTexture surfaceTexture,
            @NonNull ImageProcessor.Output.Purpose purpose,
            int rotationDegrees
    ) {
        return ImageProcessors.outputFrom(surfaceTexture, purpose, rotationDegrees);
    }

    @NonNull
    @Override
    public ImageProcessor.Output imageProcessorOutputFrom(
            @NonNull Surface surface,
            @NonNull ImageProcessor.Output.Purpose purpose,
            int rotationDegrees
    ) {
        return ImageProcessors.outputFrom(surface, purpose, rotationDegrees);
    }

    @Override
    public <P extends ImageProcessor> Bitmap imageProcessorToBitmap(
            @NonNull P processor,
            int width,
            int height,
            int rotationDegrees
    ) {
        return ImageProcessors.toBitmap(processor, width, height, rotationDegrees);
    }

    @Override
    public <P extends ImageProcessor> Bitmap imageProcessorProcessBitmap(
            @NonNull P processor,
            @NonNull ImageProcessor.Input input,
            @NonNull Bitmap bitmap,
            long timeout,
            @NonNull TimeUnit timeoutUnit
    ) {
        return ImageProcessors.processBitmap(processor, input, bitmap, Integer.MIN_VALUE, timeout, timeoutUnit);
    }

    @Override
    public <P extends ImageProcessor> Bitmap imageProcessorProcessBitmap(
            @NonNull P processor,
            @NonNull ImageProcessor.Input input,
            @NonNull Bitmap bitmap,
            int rotation,
            long timeout,
            @NonNull TimeUnit timeoutUnit
    ) {
        return ImageProcessors.processBitmap(processor, input, bitmap, rotation, timeout, timeoutUnit);
    }

    @Override
    public <P extends ImageProcessor> Bitmap imageProcessorProcessBitmap(
            @NonNull P processor,
            @NonNull ImageProcessor.Input input,
            @NonNull Bitmap bitmap,
            boolean mirrorHorizontally,
            boolean mirrorVertically,
            int rotation,
            long timeout,
            @NonNull TimeUnit timeoutUnit
    ) {
        return ImageProcessors.processBitmap(
                processor, input, bitmap, rotation, timeout, timeoutUnit, mirrorHorizontally, mirrorVertically);
    }

    @Override
    public <P extends ImageProcessor> Bitmap imageProcessorProcessImage(
            @NonNull P processor,
            @NonNull ImageProcessor.Input input,
            @NonNull Image image,
            long timeout,
            @NonNull TimeUnit timeoutUnit
    ) {
        return ImageProcessors.processImage(processor, input, image, Integer.MIN_VALUE, timeout, timeoutUnit);
    }

    @Override
    public <P extends ImageProcessor> Bitmap imageProcessorProcessImage(
            @NonNull P processor,
            @NonNull ImageProcessor.Input input,
            @NonNull Image image,
            int rotation, long timeout,
            @NonNull TimeUnit timeoutUnit
    ) {
        return ImageProcessors.processImage(processor, input, image, rotation, timeout, timeoutUnit);
    }

    @Override
    public <P extends ImageProcessor> Bitmap imageProcessorProcessImage(
            @NonNull P processor,
            @NonNull ImageProcessor.Input input,
            @NonNull Image image,
            boolean mirrorHorizontally,
            boolean mirrorVertically,
            int rotation,
            long timeout,
            @NonNull TimeUnit timeoutUnit
    ) {
        return ImageProcessors.processImage(
                processor, input, image, rotation, timeout, timeoutUnit, mirrorHorizontally, mirrorVertically);
    }

    @NonNull
    @Override
    public <P extends ImageProcessor> Closeable imageProcessorConnectOutput(
            @NonNull P processor,
            @NonNull TextureView textureView
    ) {
        return ImageProcessors.connectOutput(processor, textureView);
    }

    @NonNull
    @Override
    public <P extends ImageProcessor> Closeable imageProcessorConnectOutput(
            @NonNull P processor,
            @NonNull File file,
            int width,
            int height,
            boolean captureAudio
    ) {
        return ImageProcessors.connectOutput(processor, file, width, height, captureAudio);
    }

    @NonNull
    @Override
    public <P extends ImageProcessor> Closeable imageProcessorConnectInput(
            @NonNull P processor,
            @NonNull File file,
            int rotationDegrees,
            boolean facingFront,
            float horizontalFieldOfView,
            float verticalFieldOfView) {
        return ImageProcessors.connectInput(
                processor, context, file, rotationDegrees, facingFront, horizontalFieldOfView, verticalFieldOfView);
    }

    @NonNull
    @Override
    public Source<ImageProcessor> imageProcessorSourceFrom(
            @NonNull File file,
            int rotationDegrees,
            boolean facingFront,
            float horizontalFieldOfView,
            float verticalFieldOfView) {
        return ImageProcessors.sourceFrom(
                context, file, rotationDegrees, facingFront, horizontalFieldOfView, verticalFieldOfView);
    }

    @NonNull
    @Override
    public Source<AudioProcessor> audioProcessorMicrophoneSourceFor(
            @NonNull ExecutorService executorService
    ) {
        return AudioProcessors.microphoneSourceFor(executorService);
    }

    @NonNull
    @Override
    public AudioProcessor.Input.Frame audioProcessorInputFrameFrom(@NonNull byte[] buffer, int samplesCount) {
        return AudioProcessors.inputFrameFrom(buffer, samplesCount);
    }

    @NonNull
    @Override
    public LensesComponent.Lens.LaunchData.Builder newLensLaunchDataBuilder() {
        return LensesLaunchData.newBuilder();
    }
}
