# Camera Kit Basic Sample

This example app shows the most simplistic Camera Kit implementation, applying a single lens. 

Whether you are building a brand new app or integrating Camera Kit in your existing app, this could 
be the starting point from where you can build custom UX or logics around Camera Kit. 

We recommend you to add error handling, capture and share buttons on top of this app.

## Build

1) Open project's `AndroidManifest.xml` file and update value for `com.snap.camerakit.api.token` This can be found under IDs and Tokens in your [Lenses Portal](https://my-lenses.snapchat.com/) (Under the apps tab).
2) Within the `sample/basic/MainActivity.kt` file, update the values for `LENS_GROUP_ID` and `LENS_ID` with your desired lens, also retrieved from the Lenses Portal. 

To build, install and launch the `camerakit-sample-basic` on a connected device follow one of the following options:

### Command Line

- `./gradlew camerakit-sample-basic:installDebug`

- `adb shell am start -n com.snap.camerakit.sample.basic/com.snap.camerakit.sample.basic.  
  MainActivity`

### IDE

Select the `camerakit-sample-basic` module configuration and click run:

![run-android-studio](../.doc/sample_basic_run_android_studio.png)

## Steps to integrate Camera Kit

1) Add the required dependencies for Camera Kit:

```
// Provides the core implementation of Camera Kit`  
implementation "com.snap.camerakit:camerakit:$cameraKitVersion"  

// [Optional] Implementation of Camera pipeline for Camera Kit using CameraX library  
implementation "com.snap.camerakit:support-camerax:$cameraKitVersion" 
 ```

2) In your layout xml file, add a `ViewStub` and attach that to Camera Kit `Session` using `attachTo` method. Provided `ViewStub` will inflate view hierarchy of `Session` which includes rendering camera preview with lenses. If no `ViewStub` is provided then `Session` does not attempt to render any views while the output of camera preview can be attached to using `ImageProcessor.connectOutput`. If you cannot provide `ViewStub` and connect output manually then it will not be possible for lenses to receive user’s touch input.

Add `ViewStub` to xml like this:
 ``` 
<ViewStub  
	android:id="@+id/camera_kit_stub"
	android:layout_width="match_parent"  
	android:layout_height="match_parent" />  
```
3) Pass this View to Camera Kit `Session` like this:
  ```
import com.snap.camerakit.invoke
import com.snap.camerakit.support.camerax.CameraXImageProcessorSource

val imageProcessorSource = CameraXImageProcessorSource(
    context = this,
    lifecycleOwner = this
)

val cameraKitSession = Session(context = this) {
    apiToken(ADD_API_TOKEN_HERE)
    imageProcessorSource(imageProcessorSource)
    attachTo(findViewById(R.id.camera_kit_stub))
}.apply {
    lenses.repository.observe(
        LensesComponent.Repository.QueryCriteria.ById(ADD_LENS_ID_HERE, ADD_GROUP_ID_HERE)
    ) { result ->
        result.whenHasFirst { requestedLens ->
            // applying the Lens here
            lenses.processor.apply(requestedLens)
        }
    }
}
```