package com.snap.camerakit.sample;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.snap.camerakit.plugin.Plugin;
import com.snap.camerakit.sample.dynamic.app.BuildConfig;
import com.snap.camerakit.sample.dynamic.app.R;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static java.util.Collections.singletonList;

/**
 * A simple activity that demonstrates loading CameraKit implementation library on demand as a plugin that lives in
 * a separate apk installation.
 * When user clicks on "START CAMERAKIT" button we attempt to load {@link Plugin} and, it it succeeds, we attach a new
 * view dynamically (with the purpose of delaying CameraKit SDK class loading) which requests a group of lenses
 * to be displayed as a list of items that can be clicked on to preview on a pre-recorded video.
 */
public final class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private static final String TEST_VIDEO_FILE_LENS_PREVIEW = "object_pet_video.mp4";

    private final ExecutorService backgroundExecutor = Executors.newSingleThreadExecutor();

    private Plugin cameraKitPlugin;

    private LinearLayout rootLayout;
    private Button startCameraKitButton;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);
        rootLayout = findViewById(R.id.root_layout);

        startCameraKitButton = findViewById(R.id.start_camerakit_button);
        startCameraKitButton.setOnClickListener(v -> {
            v.setEnabled(false);
            tryInstallCameraKit(Plugin.Loader.from(
                    this,
                    BuildConfig.DYNAMIC_PLUGIN_CAMERAKIT,
                    singletonList("BF7AF0D491B22B21F183226F838E9B91AC388E95E896CF8CAB6BBE51D6382298")
            ));
        });
    }

    @Override
    protected void onDestroy() {
        backgroundExecutor.shutdown();
        super.onDestroy();
    }

    private void tryInstallCameraKit(Plugin.Loader loader) {
        if (cameraKitPlugin != null) {
            Log.w(TAG, "CameraKit feature has been setup already");
            startCameraKitButton.setVisibility(android.view.View.GONE);
        } else {
            backgroundExecutor.execute(() -> {
                Plugin.Loader.Result loadResult = loader.load();
                if (loadResult instanceof Plugin.Loader.Result.Failure) {
                    runOnUiThread(() -> {
                        startCameraKitButton.setEnabled(true);
                        Toast.makeText(
                                MainActivity.this,
                                getString(
                                        R.string.message_camerakit_start_failure,
                                        ((Plugin.Loader.Result.Failure) loadResult).getMessage()),
                                Toast.LENGTH_LONG)
                                .show();

                    });
                } else if (loadResult instanceof Plugin.Loader.Result.Success) {
                    cameraKitPlugin = ((Plugin.Loader.Result.Success) loadResult).getPlugin();

                    File videoFile = new File(getCacheDir(), TEST_VIDEO_FILE_LENS_PREVIEW);
                    try (InputStream source = getClassLoader().getResourceAsStream(TEST_VIDEO_FILE_LENS_PREVIEW);
                         OutputStream target = new FileOutputStream(videoFile)
                    ) {
                        Streams.copy(source, target);
                    } catch (IOException e) {
                        throw new RuntimeException("Failed to copy lens preview video", e);
                    }

                    runOnUiThread(() -> {
                        startCameraKitButton.setVisibility(View.GONE);
                        CameraKitView cameraKitView = new CameraKitView(MainActivity.this);
                        rootLayout.addView(cameraKitView,
                                new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));
                        cameraKitView.startSessionFrom(cameraKitPlugin, videoFile);
                    });
                }
            });
        }
    }
}
