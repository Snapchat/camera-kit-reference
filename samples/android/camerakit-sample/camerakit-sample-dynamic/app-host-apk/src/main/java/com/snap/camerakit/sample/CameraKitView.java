package com.snap.camerakit.sample;

import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewStub;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.DividerItemDecoration;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.snap.camerakit.Session;
import com.snap.camerakit.lenses.LensesComponent.Repository.QueryCriteria.Available;
import com.snap.camerakit.lenses.LensesComponent.Repository.Result;
import com.snap.camerakit.plugin.Plugin;
import com.snap.camerakit.sample.dynamic.app.R;

import java.io.File;

import static com.snap.camerakit.sample.dynamic.app.BuildConfig.LENS_GROUP_ID_TEST;

/**
 * Standalone {@link View} that displays a list of lenses and a mini video preview for a selected lens. This class
 * isolates all interactions with the public CameraKit SDK classes so that they are not touched before CameraKit
 * {@link Plugin} is loaded. While this class is a simple demonstration, in any real application that loads CameraKit
 * via {@link com.snap.camerakit.plugin.Plugin.Loader} it is essential to structure code with class loading isolation
 * in mind, otherwise application will crash due to class loading failures.
 */
class CameraKitView extends FrameLayout {

    private static final String TAG = "CameraKitView";

    private final RecyclerView lensesListView;
    private final View lensesUnavailableView;
    private final ViewStub cameraKitViewStub;
    private final ContentLoadingProgressBar loadingIndicator;

    private Session cameraKitSession;

    CameraKitView(@NonNull Context context) {
        super(context);

        LayoutInflater.from(context).inflate(R.layout.camerakit_view, this);

        lensesListView = findViewById(R.id.lenses_list);
        lensesListView.setLayoutManager(new LinearLayoutManager(context, LinearLayoutManager.VERTICAL, false));
        DividerItemDecoration itemDecoration = new DividerItemDecoration(context, DividerItemDecoration.VERTICAL);
        itemDecoration.setDrawable(getResources().getDrawable(R.drawable.divider));
        lensesListView.addItemDecoration(itemDecoration);

        lensesUnavailableView = findViewById(R.id.lenses_unavailable);
        cameraKitViewStub = findViewById(R.id.camerakit_stub);

        loadingIndicator = findViewById(R.id.loading_indicator);
        loadingIndicator.hide();
    }

    void startSessionFrom(Plugin cameraKitPlugin, File videoFile) {
        loadingIndicator.show();

         cameraKitSession = cameraKitPlugin
                .newSessionBuilder()
                .imageProcessorSource(cameraKitPlugin.imageProcessorSourceFrom(videoFile))
                .attachTo(cameraKitViewStub)
                .build();

        cameraKitSession.getLenses().getRepository().get(new Available(LENS_GROUP_ID_TEST), result -> {
                Log.d(TAG, "Lenses query result: " + result);
                post(() -> {
                    loadingIndicator.hide();
                    lensesUnavailableView.setVisibility(View.GONE);
                    if (result instanceof Result.Some) {
                        LensListAdapter lensListAdapter = new LensListAdapter(
                                ((Result.Some) result).getLenses(),
                                lens -> {
                                    Log.d(TAG, "Clicked on: " + lens);
                                    cameraKitSession.getLenses().getProcessor().apply(lens, success -> {
                                        Log.d(TAG, "Applied lens [" + lens + "]: " + success);
                                    });
                                });
                        lensesListView.setAdapter(lensListAdapter);
                    } else {
                        lensesUnavailableView.setVisibility(View.VISIBLE);
                    }
                });
            });
    }

    @Override
    protected void onDetachedFromWindow() {
        if (cameraKitSession != null) {
            cameraKitSession.close();
        }
        super.onDetachedFromWindow();
    }
}
