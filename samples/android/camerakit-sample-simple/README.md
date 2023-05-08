# Camera Kit Sample Simple App

An app that demonstrates how to launch the Camera Kit's support `CameraActivity` with different parameters and get results back:

![demo](../.doc/sample_simple_demo.gif)

The full-featured `CameraActivity` is a great option for existing apps to integrate Camera Kit without much additional code with the most minimal setup being:

- Add to a `build.gradle`:
    ```groovy
    // Add dependency to the CameraActivity support artifact which pulls all the other necessary dependencies
    implementation "com.snap.camerakit:support-camera-activity:$cameraKitVersion"
    ```
- Add to an `Activity`:
    ```kotlin
    val captureLauncher = registerForActivityResult(CameraActivity.Capture) { result ->
        if (result is CameraActivity.Capture.Result.Success) {
            // ...
        }
    }
    findViewById<Button>(R.id.some_button).setOnClickListener {
        captureLauncher.launch(CameraActivity.Configuration.WithLenses(
            // NOTE: replace the values with values obtained from https://kit.snapchat.com/manage
            cameraKitApiToken = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE",
            // NOTE: replace the value with lenses group ID from https://camera-kit.snapchat.com
            lensGroupIds = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
        ))
    }
    ```

## Build

To build, install and launch the `camerakit-sample-simple` on a connected device:

### Command Line

- `./gradlew camerakit-sample-simple:installDebug`

- `adb shell am start -n com.snap.camerakit.sample.simple/com.snap.camerakit.sample.MainActivity`

### IDE

Select the `camerakit-sample-simple` module configuration and click run:

![run-android-studio](../.doc/sample_simple_run_android_studio.png)
