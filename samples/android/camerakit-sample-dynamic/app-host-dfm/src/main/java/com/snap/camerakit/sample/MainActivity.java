package com.snap.camerakit.sample;

import static com.snap.camerakit.sample.dynamic.app.BuildConfig.LENS_GROUP_ID_TEST;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewStub;
import android.widget.Button;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.widget.ContentLoadingProgressBar;

import com.google.android.play.core.splitinstall.SplitInstallManager;
import com.google.android.play.core.splitinstall.SplitInstallManagerFactory;
import com.google.android.play.core.splitinstall.SplitInstallRequest;
import com.google.android.play.core.splitinstall.model.SplitInstallSessionStatus;
import com.google.android.play.core.tasks.Task;
import com.snap.camerakit.Session;
import com.snap.camerakit.plugin.Plugin;
import com.snap.camerakit.sample.dynamic.app.BuildConfig;
import com.snap.camerakit.sample.dynamic.app.R;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * A simple activity that demonstrates loading CameraKit implementation library on demand through a dynamic feature
 * module.
 * When user clicks on "START CAMERAKIT" button we install CameraKit dynamic feature module and then attempt to load
 * the CameraKit's {@link Plugin} which provides a simplified interface to all the necessary CameraKit implementation
 * APIS. If loading of the {@link Plugin} succeeds we then create a new CameraKit {@link Session} that presents lenses
 * carousel activated on top of a pre-recorded video preview that is used as an image processing input.
 */
public final class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private static final String TEST_VIDEO_FILE_LENS_PREVIEW = "object_pet_video.mp4";

    private SplitInstallManager splitInstallManager;
    private Task<Integer> installTask;
    private Plugin cameraKitPlugin;
    private Session cameraKitSession;

    private ContentLoadingProgressBar loadingIndicator;
    private Button startCameraKitButton;
    private ViewStub cameraKitViewStub;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        splitInstallManager = SplitInstallManagerFactory.create(this);

        setContentView(R.layout.activity_main);
        loadingIndicator = findViewById(R.id.loading_indicator);
        loadingIndicator.hide();

        startCameraKitButton = findViewById(R.id.start_camerakit_button);
        startCameraKitButton.setOnClickListener(v -> {
            v.setEnabled(false);
            loadingIndicator.show();
            tryLoadCameraKitPlugin();
        });

        cameraKitViewStub = findViewById(R.id.camerakit_stub);
    }

    @Override
    protected void onDestroy() {
        if (cameraKitSession != null) {
            cameraKitSession.close();
        }
        super.onDestroy();
    }

    private void tryLoadCameraKitPlugin() {
        if (splitInstallManager.getInstalledModules().contains(BuildConfig.DYNAMIC_FEATURE_CAMERAKIT)) {
            Plugin.Loader loader = Plugin.Loader.from(this, getClassLoader());
            Plugin.Loader.Result loadResult = loader.load();
            if (loadResult instanceof Plugin.Loader.Result.Failure) {
                Toast.makeText(
                        this,
                        getString(R.string.message_camerakit_start_failure,
                                ((Plugin.Loader.Result.Failure) loadResult).getMessage()),
                        Toast.LENGTH_LONG)
                        .show();
            } else if (loadResult instanceof Plugin.Loader.Result.Success) {
                onCameraKitPluginLoaded(((Plugin.Loader.Result.Success) loadResult).getPlugin());
            }
        } else {
            tryInstallCameraKitPluginAsDynamicFeature();
        }
    }

    private void tryInstallCameraKitPluginAsDynamicFeature() {
        if (installTask == null) {
            SplitInstallRequest installRequest = SplitInstallRequest
                    .newBuilder()
                    .addModule(BuildConfig.DYNAMIC_FEATURE_CAMERAKIT)
                    .build();
            installTask = splitInstallManager.startInstall(installRequest)
                    .addOnFailureListener(e -> {
                        installTask = null;
                        runOnUiThread(() -> {
                            Toast.makeText(
                                    this,
                                    getString(R.string.message_camerakit_start_failure, e.getMessage()),
                                    Toast.LENGTH_LONG).show();
                            loadingIndicator.hide();
                            startCameraKitButton.setEnabled(true);
                        });
                    });
            splitInstallManager.registerListener(state -> {
                if (state.status() == SplitInstallSessionStatus.INSTALLED) {
                    Toast.makeText(this, R.string.message_camerakit_load_feature, Toast.LENGTH_SHORT).show();
                    tryLoadCameraKitPlugin();
                }
            });
        }
    }

    private void onCameraKitPluginLoaded(Plugin plugin) {
        if (cameraKitPlugin != null) {
            Log.w(TAG, "CameraKit feature has been setup already");
            loadingIndicator.hide();
            startCameraKitButton.setVisibility(View.GONE);
        } else {
            cameraKitPlugin = plugin;

            loadingIndicator.hide();
            startCameraKitButton.setVisibility(View.GONE);

            File videoFile = new File(getCacheDir(), TEST_VIDEO_FILE_LENS_PREVIEW);
            try (InputStream source = getClassLoader().getResourceAsStream(TEST_VIDEO_FILE_LENS_PREVIEW);
                 OutputStream target = new FileOutputStream(videoFile)
            ) {
                Streams.copy(source, target);
            } catch (IOException e) {
                throw new RuntimeException("Failed to copy lens preview video", e);
            }

            cameraKitSession = cameraKitPlugin
                    .newSessionBuilder()
                    .attachTo(cameraKitViewStub)
                    .imageProcessorSource(cameraKitPlugin.imageProcessorSourceFrom(videoFile))
                    .configureLenses(builder ->
                            builder.configureCarousel(configuration ->
                                    configuration.observeGroupIds(LENS_GROUP_ID_TEST))
                    )
                    .build();
        }
    }
}
