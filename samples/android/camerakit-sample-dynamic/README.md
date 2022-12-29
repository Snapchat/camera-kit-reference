# Camera Kit Dynamic Loading

Demonstrates how to integrate the CameraKit SDK into an app that loads the SDK dynamically as an on-demand feature. Dynamic loading is useful for use cases where size of the Camera Kit SDK is considered to be too big to be included together with the core app features. To support such use cases, the public Camera Kit interfaces and classes are available in a separate `camerakit-api` and special `camera-kit-plugin-api` Maven artifacts that should have everything necessary to interface with Camera Kit SDK in the core app.

## Host app loading Camera Kit from another APK

The sample [`app-host-apk`](./app-host-apk) loads Camera Kit SDK through the provided `Plugin.Loader` interface by looking up the implementation [`plugin-apk`](./plugin-apk) app of known package ID installed as a separate apk. When user clicks on the **START CAMERAKIT** button, we attempt to load `Plugin` from a separate apk and, if loading of the Camera Kit `Plugin` is successful, we then present user with a list of available lenses that can can be clicked on to preview:

![demo](../.doc/sample_dynamic_demo_apk.gif)

### Build

To build, install and launch `camerakit-sample-dynamic-app-host-apk` with:

-  `camerakit-sample-dynamic-plugin-apk` installed separately on a connected device:

    - Command Line

        - `./gradlew camerakit-sample-dynamic-app-host-apk:installDebug`
        
        - `./gradlew camerakit-sample-dynamic-plugin-apk:installDebug`
        
        - `adb shell am start -n com.snap.camerakit.sample.dynamic.app/com.snap.camerakit.sample.MainActivity`

## Host app loading CameraKit as a dynamic feature module

The sample [`app-host-dfm`](./app-host-dfm) loads Camera Kit SDK through the provided `Plugin.Loader` interface once the [`plugin-dfm`](./plugin-dfm) [dynamic feature module](https://developer.android.com/guide/playcore/feature-delivery) is installed. When user clicks on the **START CAMERAKIT** button, we attempt to load `Plugin` from the installed dynamic feature module and, if loading of the Camera Kit `Plugin` is successful, we then present user with a default Camera Kit interface (lenses carousel etc.) rendered on top of a video preview which is used as an image processing input:

![demo](../.doc/sample_dynamic_demo_dfm.gif)

### Build

To build, install and launch `camerakit-sample-dynamic-app-host-dfm`:

- Command Line

   - `./gradlew camerakit-sample-dynamic-app-host-dfm:installDebug`

   - `./gradlew camerakit-sample-dynamic-app-host-dfm:installApkSplitsForTestDebug`

   - `adb shell am start -n com.snap.camerakit.sample.dynamic.app/com.snap.camerakit.sample.MainActivity`
