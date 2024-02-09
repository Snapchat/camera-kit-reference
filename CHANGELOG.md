# CHANGELOG

All notable changes to the Camera Kit SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and the Camera Kit SDK adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<a name="unreleased"></a>
## [Unreleased]

<a name="1.28.0"></a>
## [1.28.0] - 2024-02-08
### Bug Fixes
- **Android:** Fix an issue when `LensesComponent.Processor#clear()` doesn&#39;t remove a lens while using custom UI.
- **Android:** Fix a crash when using Push-To-Device.

<a name="1.27.0"></a>
## [1.27.0] - 2023-12-13
### Features
- Lens Studio 5.0.2 support

### Updates
- **Android:** Addressed behavior changes for apps targetting Android 14 or higher ([behavior-changes-14](https://developer.android.com/about/versions/14/behavior-changes-14)).  

<a name="1.26.2"></a>
## [1.26.2] - 2023-11-13
- **IOS:** Fix face detection for 3+ faces on IOS front camera.
- **iOS:** Update CocoaPods's pod names to SCCameraKit, SCCameraKitReferenceUI, SCCameraKitReferenceSwiftUI, SCCameraKitLoginKitAuth, SCCameraKitBaseExtension, SCCameraKitConnectedLensesExtension, SCCameraKitPushToDeviceExtension from this release on. Framework names in code remain the same.

<a name="1.26.1"></a>
## [1.26.1] - 2023-10-12
### Bug Fixes
- Lens elements that use overlay render target may be get incorrectly positioned when camera input does not match preview output aspect ratio
- **Android:** Lens audio playback is not muted when app is paused
- **Android:** [HIGH_SAMPLING_RATE_SENSORS](https://developer.android.com/reference/android/Manifest.permission#HIGH_SAMPLING_RATE_SENSORS) permission declaration is missing in the core SDK manifest
- **Android:** Early display rotation notification causing incorrect input processing size calculation on Android 14

<a name="1.26.0"></a>
## [1.26.0] - 2023-09-13 - _LTS_
### Features
- Lens Studio 4.55 support

### Updates
- **Android:** Helper method to record `ImageProcessor` output into a video file, `connectOutput(file: File, width: Int, height: Int, captureAudio: Boolean)`, has been moved into a separate Maven artifact,  `com.snap.camerakit:support-media-recording`. This artifact can now be excluded from an app&#39;s dependencies if the provided video recording functionality is not needed. Note that the `com.snap.camerakit:support-camerax`  and  `com.snap.camerakit:support-arcore` now depend on this new artifact transitively in order to implement the `com.snap.camerakit.support.camera.AllowsVideoCapture` interface.
- **Android:** Helper method to create an instance of `Source<MediaProcessor>` based on `android.provider.MediaStore`, `mediaStoreSourceFor(context: Context, executorService: ExecutorService): Source<MediaProcessor>`, has been moved into a separate Maven artifact, `com.snap.camerakit:support-media-picker-source`. This artifact can now be excluded from an app&#39;s dependencies if the provided media source functionality is not needed. Note that the `com.snap.camerakit:support-camera-layout` now depends on this new artifact transitively in order to obtain media for media picker lenses.
- **Android:** Default lenses carousel UI has been removed from the core `com.snap.camerakit:camerakit` artifact. Instead, `com.snap.camerakit:support-lenses-carousel` artifact should be added to app dependencies to use default lenses carousel UI. Note that the `com.snap.camerakit:support-camera-layout` now depends on this artifact transitively in order to show lenses carousel UI.
- **Android:** Default media picker UI has been moved from the core `com.snap.camerakit:camerakit` artifact, and moved into a separate Maven artifact, `com.snap.camerakit:support-media-picker-ui`. This new artifact should be added to app dependencies to use default media picker UI. Note that the `com.snap.camerakit:support-camera-layout` now depends on this new artifact transitively in order to show media picker UI.

### Bug Fixes
- **iOS:** Wrong camera orientation after device rotation on iOS 16 and later

### Known Issues
- Lens UI elements assinged to the overlay render target can get incorrectly positioned when device camera input frame does not match preview preview frame aspect ratio

<a name="1.25.0"></a>
## [1.25.0] - 2023-08-15
### Features
- Lens Studio 4.53 support

### Bug Fixes
- **Android:** Fix a bug in the ARCore field of view, which was causing poor performance and incorrect object positioning for world tracking lenses
- **Android:** Fix a bug when the first lens in the carousel has not been applied if `LensesComponent.Carousel.Configuration#disableIdle` set to `true`

<a name="1.24.0"></a>
## [1.24.0] - 2023-06-27
### Features
- Lens Studio 4.49 support
- **Android:** Add a Profiling Extension to monitor the Camera Kit performance. See [Profiling](./samples/android/Profiling.md).
- **Android:** Add a new API to get lens snapcode image and deep link URIs, usage example:
    ```kotlin
     session.lenses.repository.get(LensesComponent.Repository.QueryCriteria.Available("lens-group-id")) { result ->
    	result.whenHasFirst { lens -> 
			  val snapcodePngUri = lens.snapcodes.find { it is LensesComponent.Lens.Media.Image.Png }?.uri
			  val snapcodeDeepLinkUri = lens.snapcodes.any { it is LensesComponent.Lens.Media.DeepLink }?.uri
		}
    }
    ```

### Updates
- **iOS:** Add a debug dialog to swap API token for testing
- **iOS:** Add support for configuring debug dialogs via deep links/qr codes.
- **Android:** Added `android.Manifest.permission.READ_MEDIA_VIDEO` and `android.Manifest.permission.READ_MEDIA_IMAGES` permissions for the 
`camerakit-sample-full` and `camerakit-sample-simple` apps. Those are the permissions required to access media files on devices when using the 
Media Picker lenses feature.

### Bug Fixes
- **iOS:** Fix a bug where certain assets could be loaded later than expected, potentially causing the lens to fail to load entirely if device was offline.

<a name="1.23.0"></a>
## [1.23.0] - 2023-05-17
### Features
- Lens Studio 4.47 support
- **Android:** Add a new API to get lens preview sequences - `LensesComponent.Lens.Media.Sequence`, usage example:
    ```kotlin
    session.lenses.repository.get(LensesComponent.Repository.QueryCriteria.Available("lens-group-id")) { result ->
    	result.whenHasFirst { lens -> 
			(lens.previews.find { preview -> 
	        		preview is LensesComponent.Lens.Media.Sequence.Webp 
	    		} as? LensesComponent.Lens.Media.Sequence.Webp)?.let { webpSequence ->
	       			webpSequence.values.forEach { imageUri ->
		    			// do something with each image
				}
	    		}
		}
    }
    ```
- **Android:** Prompt users to install a new ArCore version when available when using lenses that require it

### Bug Fixes
- **iOS:** Fix share button working as save button in the reference UI
    
<a name="1.22.0"></a>
## [1.22.0] - 2023-05-08
### Updates
- Deprecate application ID, remove its use across sample apps
- **Android:** Add a debug dialog to swap API token for testing

### Features
- Lens Studio 4.46 support

### Bug Fixes
- **Android:** Fix a bug introduced in the `1.18.0` version where lenses exported from the Lens Studio version `4.31` and prior can lead to a crash on Adreno GPU based devices
- **iOS:** Fix a bug in the reference UI where tapping share button leads to a crash on iPad

<a name="1.21.1"></a>
## [1.21.1] - 2023-03-29
### Bug Fixes
- **iOS:** Fixed issue where photos of certain lenses could output a blank image
- **iOS:** Fixed issue where touch handling could be processed incorrectly

<a name="1.21.0"></a>
## [1.21.0] - 2023-03-24
### Features
- Lens Studio 4.43 support

<a name="1.20.0"></a>
## [1.20.0] - 2023-02-21
### Updates
- **Android:** Remove "Share with Snapchat" placeholder button
- **Android:** Add examples on how to remove the control strip from the `CameraActivity`

### Features
- Lens Studio 4.40 support
- **Android:** Add a way to collect Camera Kit diagnostics information on-demand. This feature can be enabled when an issue in Camera Kit is encountered, please reach out to the Camera Kit support for further instructions. 

### Bug Fixes
- **iOS:** Fixed bug where login flow could fail during Push to Device configuration
- Fix Snap attribution view is not shown outside of US

<a name="1.19.2"></a>
## [1.19.2] - 2023-01-12
### Bug Fixes
- **iOS:**  Fix the issue of staging watermark showing with production API token

<a name="1.19.1"></a>
## [1.19.1] - 2023-01-09
### Bug Fixes
- **Android:**  Fix a crash caused by `RejectedExecutionException` after `Session` is closed

<a name="1.19.0"></a>
## [1.19.0] - 2022-12-28
### Features
- Lens Studio 4.36 support
- Add a new sample app that demonstrates a custom implementation of lenses carousel and camera preview layout
- **iOS** Add a debug menu to the sample app to customize lens groups at runtime 

### Updates
- **Android:** Remove deprecated lens icon/preview accessors:
	- `LensesComponent.Lens.iconUri` replaced by `icons.find { it is LensesComponent.Lens.Media.Image.Png }?.uri`
	- `LensesComponent.Lens.preview` replaced by `previews.find { it is LensesComponent.Lens.Media.Image.Webp }?.uri`

### Bug Fixes
- **Android:**  Fix occasional camera preview freeze in `CameraXImageProcessorSource` when switching from an ARCore based camera preview source 

<a name="1.18.1"></a>
## [1.18.1] - 2022-11-30
### Bug Fixes
- **Android:**  Fix an issue where touch gestures are not be processed by lenses if no `View` is provided to `LensesComponent.Builder#dispatchTouchEventsTo`

<a name="1.18.0"></a>
## [1.18.0] - 2022-11-21
### Features
- Lens Studio 4.34 support
- [Custom Location AR](https://docs.snap.com/lens-studio/references/templates/landmarker/custom-landmarker) (Beta feature) support

### Updates
- Snap attribition support as per [Design Guidelines](https://docs.snap.com/snap-kit/camera-kit/release/design-guide)
- Staging Watermark applies on staging builds of Camera Kit integrations
- **iOS:** Xcode 14 or above required
- **iOS:** Discontinued support on iOS 11 and lower
- **Android:**  Update CameraX dependencies to 1.1.0
- **Android:**  Update sample app project to the latest Gradle/AGP 7+ and Kotlin 1.6.21 versions

### Bug Fixes
- **Android:** Fix crash due to exceeded number of listeners registered via `TelephonyRegistryManager`

<a name="1.17.1"></a>
## [1.17.1] - 2022-11-30
### Bug Fixes
- **Android:**  Fix an issue where touch gestures are not be processed by lenses if no `View` is provided to `LensesComponent.Builder#dispatchTouchEventsTo`

<a name="1.17.0"></a>
## [1.17.0] - 2022-10-12
### Features
- Lens Studio 4.31 support
- Add support for City-Scale AR Lenses (Beta)
- Add support for Push-to-Device (P2D) feature (Beta), which allows developers to send Lenses from Lens Studio to their Camera Kit application for testing. Note that on Android, P2D is only supported if your application uses the built-in lenses carousel.
- **Android:**  Expose new API to obtain WebP lens icon resources, switch the built-in lenses carousel to use it by default. Note that PNG lens icon resources are deprecated, to be removed in 1.19.0.

### Bug Fixes
- **Android:**  Fix an issue causing ArCore camera freeze

<a name="1.16.0"></a>
## [1.16.0] - 2022-09-09
### Features
- Lens Studio 4.28.x support
- Add support for Connected Lenses (Closed Beta)
- **iOS** Add support for arm64 simulators

<a name="1.15.1"></a>
## [1.15.1] - 2022-07-20
### Bug Fixes
- **Android:**  Fix crash when switching ArCore powered lenses

<a name="1.15.0"></a>
## [1.15.0] - 2022-07-18
### Notes
- This version has critical issues on Android. Use version 1.15.1 instead

### Features
- Lens Studio 4.25 support
- **Android** New method to apply a lens while resetting its state if the lens was applied already. Useful for cases where app resume from background or other screen should reset lens state matching Snapchat-like behavior. Usage example: 
	`session.lenses.processor.apply(lens, reset = true)`

### Bug Fixes
- **Android:**  Improve ARCore performance
- **Android:**  Fix possible crash when internal remote service is not available

<a name="1.14.1"></a>
## [1.14.1] - 2022-06-30
### Bug Fixes
- **Android:**  Fix critical issues with lenses configuration introduced in 1.14.0

<a name="1.14.0"></a>
## [1.14.0] - 2022-06-27
### Notes
- This version has critical issues on Android. Use version 1.14.1 instead

### Features
- Lens Studio 4.22 support
- Add support for lenses with static assets
- **Android**  New API to obtain the current version of the Camera Kit SDK
- **iOS** Add standard flash along with ring light for front-facing flash to sample app

<a name="1.13.0"></a>
## [1.13.0] - 2022-05-27
### Features
- New API to support lenses which use the remote service [feature](https://docs.snap.com/lens-studio/references/guides/lens-features/remote-apis/remote-service-module)
- New tone-mapping and portrait camera adjustments
- **Android:**  Add support for ring flash mode for front-facing camera flash
- **iOS:**  Add explicit viewport configuration to SCCameraKitPreviewView

### Bug Fixes
- **Android:**  Add missing permission HIGH_SAMPLING_RATE_SENSORS for host-apk dynamic sample
- **Android:**  Fix processed bitmap rotation when no lens is applied

<a name="1.12.0"></a>
## [1.12.0] - 2022-04-22
### Notes
- Starting with this release, an API token **must** be provided as part of the Camera Kit configuration, failure to do so will result in a runtime exception. See [Android](https://docs.snap.com/snap-kit/camera-kit/configuration/android#service-authorization) and [iOS](https://docs.snap.com/snap-kit/camera-kit/configuration/ios/#service-authorization) documentation for examples on how to obtain and provide an API token.
- The legal agreement prompt has been updated to use a more user friendly text copy. Updating to this release will result in users needing to accept the updated prompt which includes a new link to the Camera Kit&#39;s "learn more" [page](https://support.snapchat.com/en-US/article/camera-information-use).

### Features
- Lens Studio 4.19 support
- **Android:**  Add dynamic feature loading (DFM) reference sample app
- **Android:**  New `ImageProcessor.Input.Option.Crop` which allows to specify the crop region that should be applied to each frame before processing
- **Android:**  `CameraXImageProcessorSource#startPreview` takes aspect ratio and crop option parameters
- **Android:**  Further binary size reduction of about 500KB

### Bug Fixes
- **Android:**  Missing `android.permission.ACCESS_COARSE_LOCATION` permission added to the `camerakit-support-gms-location` artifact to support apps targeting Android API 31
- **Android:**  Image capture of certain lenses results in an unexpected alpha channel
- **Android:**  Race condition of incorrectly evicting currently applied lens content from cache while prefetching other lenses
- **iOS:**  `LensProcessor.setAudioMuted` doesn't mute/unmute audio coming from lenses

### Known Issues
- Lenses using the new [Text to Speech](https://docs.snap.com/lens-studio/references/guides/lens-features/audio/text-to-speech) feature throw a runtime exception on Android and simply do nothing on iOS. This is expected as the feature is currently unavailable in Camera Kit.  

<a name="1.11.1"></a>
## [1.11.1] - 2022-04-05
### Bug Fixes
- Fix bug where landmarkers would not work properly

<a name="1.11.0"></a>
## [1.11.0] - 2022-03-14
### Bug Fixes
- **iOS:**  Allow recording videos up to 60 seconds by default

### Features
- Add support for text input in lenses
- Lens Studio 4.16 support

<a name="1.10.0"></a>
## [1.10.0] - 2022-02-28
### Bug Fixes
- **iOS:**  Binary size optimizations (1.3MB uncompressed savings)
- **Android:**  Use consistent directory names for files related to Camera Kit
- **Android:**  Certain emulator images fail to render lenses

### Features
- **iOS**:  Added missing "Privacy - Location When In Use Usage Description" entry in Sample App Info.plist
- **Android:**  Expose new API to switch camera facing based on lens facing preference

<a name="1.9.2"></a>
## [1.9.2] - 2022-02-10
### Bug Fixes
- **Android:**  Remove R8 specific consumer rules to support legacy Proguard builds
- **Android:**  Fix race conditions during face detection in the default Media Picker

<a name="1.9.1"></a>
## [1.9.1] - 2022-01-26
### Bug Fixes
- **Android:**  Don't start LegalPromptActivity if the legal prompt is already accepted
- **Android:**  Remote service calls fail after `Session` is used for more than 60 seconds
- **iOS:**  Fixed bug where `additionalConfigurationFlags` would not be processed correctly

<a name="1.9.0"></a>
## [1.9.0] - 2022-01-18
### Features
- Lens Studio 4.13 support
- **Android:**  Persist custom lens groups in sample app
- **iOS:**  M1/arm64 simulator support
- **iOS:**  Add support for tap to focus

### Bug Fixes
- **Android:**  Custom `Source<ImageProcessor>>` is not respected in `CameraLayout`
- **Android:**  Warn if no API token is provided	
- **iOS:**  Audio cuts out when swapping camera

<a name="1.8.4"></a>
## [1.8.4] - 2022-01-14
### Bug Fixes
- **iOS:**  SessionConfig values not being used correctly

<a name="1.8.3"></a>
## [1.8.3] - 2022-01-12
### Bug Fixes
- **Android:** Fix sharing captured media in sample app for some Android OS versions
- **Android:** Eliminate native libraries binary size regression
- **Android:** Extension fail to register when Kotlin reflect library is included
- **Android:** Remove unused code which gets flagged as [zip path traversal vulnerability](https://support.google.com/faqs/answer/9294009)
- **iOS:**  Clear out queue file if it is corrupted

### Features
- **Android:** Expose a method to observe LegalProcessor results
- **Android:** Flash functionality in `CameraLayout` and `CameraXImageProcessorSource`
- **iOS:** Expose legal agreement URLs

<a name="1.8.2"></a>
## [1.8.2] - 2021-12-15
### Bug Fixes
-  Missing localized strings
- **Android:** Lenses using ML features crash when app targets Android 12 (API level 31) 
- **Android:** Crop ARCore video to screen size by default

<a name="1.8.1"></a>
## [1.8.1] - 2021-12-09
### Bug Fixes
-  Too-large images fail to load in media picker
-  Lens content downloads use non-optimal CDN links
- **iOS:**  unknown_lens_hint blinks on activation
- **iOS:**  Rear camera not using LiDAR for depth when supported


<a name="1.8.0"></a>
## [1.8.0] - 2021-12-07
### Bug Fixes
- **Android:**  Add audio recording permission check for Custom Video Sample app
- **Android:**  Rendering performance improvement
- **Android:**  Add thread monitoring and safety to video sample
- **iOS:**  Touch targets in lenses are not aligned with actual elements
- **iOS:**  Recording keeps going past duration but animation stops
- **iOS:**  Memory leak when device is offline
- **iOS:**  gRPC objective c runtime conflicts
- **iOS:**  Rebuilt deliverable with latest toolset to prevent crashes

### Features
- **Android:**  Legal agreement prompt pop-up dialog support
- **Android:**  Rotation detection for continuous focus
- **Android:**  Tap-To-Focus support
- **Android:**  Support API token based authorization
- **Android:**  Lenses audio mute/unmute support
- **Android:**  Add sample app for custom implementation of audio and video recording
- **iOS:**  Support API token based authorization
- **iOS:**  Legal agreement prompt pop-up dialog support


<a name="1.7.6"></a>
## [1.7.6] - 2021-11-08
### Bug Fixes
-  Extension API mismatch


<a name="1.7.5"></a>
## [1.7.5] - 2021-10-28
### Bug Fixes
- **Android:**  Kotlin Intrinsics leak into the public Plugin API
- **Android:**   CameraLayout treats optional permissions as required
- **iOS:**  Memory leak when device is offline
- **iOS:**  Potential gRPC objective c runtime conflicts when host app contains gRPC
- **iOS:**  Surface tracking behaves incorrectly in portrait mode

### Features
-  Lens Studio 4.7 support


<a name="1.7.4"></a>
## [1.7.4] - 2021-10-20
### Bug Fixes
- **Android:**  Fix an issue introduced in 1.7.1 that downgraded SDK performance


<a name="1.7.3"></a>
## [1.7.3] - 2021-10-11
### Bug Fixes
- **iOS:**  Cache size config being ignored


<a name="1.7.2"></a>
## [1.7.2] - 2021-10-07
### Bug Fixes
- **iOS:**  Remove private API usage


<a name="1.7.1"></a>
## [1.7.1] - 2021-10-01
### Bug Fixes
- **iOS:**  Borders on captured images and videos
- **iOS:**  Process images at video resolution


<a name="1.7.0"></a>
## [1.7.0] - 2021-09-22
### Bug Fixes
- **Android:** Fix touch re-dispatch when lenses carousel de-activated
- **Android:** Fix multiple startPreview leading to a crash in CameraX
- **iOS:**  Deadlock on stopping session
- **iOS:** Process images at video resolution (scaling was causing layers of lens to disappear or objects to move their location in photos)

### Features
- **Android:** CameraActivity for simple use cases
- **Android:** CameraLayout support view for simplified integration
- **Android:** Lenses Carousel reference UI
- **Android:** Gallery media source support for the MediaProcessor
- **Android:** Enable/disable SnapButtonView based on lens download status
- **Android:** Added SRE metrics
- **iOS:** SwiftUI support
- **iOS:** Added SRE metrics


<a name="1.6.21"></a>
## [1.6.21] - 2021-10-11
### Bug Fixes
- **iOS:**  Cache size config being ignored


<a name="1.6.20"></a>
## [1.6.20] - 2021-10-07
### Bug Fixes
- **iOS:**  Remove private API usage


<a name="1.6.19"></a>
## [1.6.19] - 2021-10-01
### Bug Fixes
- **iOS:**  Borders on captured images and videos


<a name="1.6.18"></a>
## [1.6.18] - 2021-09-29
### Bug Fixes
-  Landmarkers localisation issues


<a name="1.6.17"></a>
## [1.6.17] - 2021-09-22
### Bug Fixes
- **Android:**  Face tracking issues introduced in 1.6.15


<a name="1.6.16"></a>
## [1.6.16] - 2021-09-20
### Bug Fixes
- **iOS:**  Button hit target may not have aligned with rendered UI


<a name="1.6.15"></a>
## [1.6.15] - 2021-09-14
### Features
-  LensStudio 4.5 support


<a name="1.6.14"></a>
## [1.6.14] - 2021-09-03
### Bug Fixes
-  Stability issues


<a name="1.6.13"></a>
## [1.6.13] - 2021-09-02
### Features
- **iOS:**  Bitcode support


<a name="1.6.12"></a>
## [1.6.12] - 2021-08-17
### Bug Fixes
- **Android:**  Lenses Carousel does not appear on some devices
- **Android:**  Avoid reading cache size config on the Main thread


<a name="1.6.11"></a>
## [1.6.11] - 2021-08-06
### Bug Fixes
- **Android:**  Lens processing failure after image/video capture
- **Android:**  SurfaceTexture based Output Surface leak


<a name="1.6.10"></a>
## [1.6.10] - 2021-07-23
### Bug Fixes
- **Android:**  Too broad Proguard rule for GMS FaceDetector


<a name="1.6.9"></a>
## [1.6.9] - 2021-07-19
### Bug Fixes
- **iOS:**  Localization always giving priority to preferred languages with 3 letter ISO 639-2 codes


<a name="1.6.8"></a>
## [1.6.8] - 2021-07-13
### Bug Fixes
- **Android:**  Fix Surface not released if Output connection is cancelled


<a name="1.6.7"></a>
## [1.6.7] - 2021-07-08
### Bug Fixes
- **Android:**  Increase max lenses content size
- **Android:**  Late input connection leads to no processed frames
- **iOS:**  Increase max lenses content size
- **iOS:**  Some lenses turn grayscale when recording


<a name="1.6.6"></a>
## [1.6.6] - 2021-06-22
### Bug Fixes
- **iOS:**  Large photo picker images (panorama) exceed memory


<a name="1.6.5"></a>
## [1.6.5] - 2021-06-17
### Bug Fixes
- **Android:**  Lens localized hint strings are cached incorrectly
- **Android:**  Incorrect lens download status


<a name="1.6.4"></a>
## [1.6.4] - 2021-06-16
### Bug Fixes
- **iOS:**  Previous lens would sometimes be applied after new one was applied


<a name="1.6.3"></a>
## [1.6.3] - 2021-06-16
### Bug Fixes
- **Android:**  Carousel accessibility improvements


<a name="1.6.1"></a>
## [1.6.1] - 2021-05-10
### Bug Fixes
- **Android:**  Lens is not applied when carousel&#39;s disableIdle = true
- **iOS:**  Deadlock on stopping session


<a name="1.6.0"></a>
## [1.6.0] - 2021-04-26
### Features
- **Android:**  Add support for client defined safe render area
- **Android:**  Add Media Picker support for sample app
- **Android:**  Switch to ARCore for surface tracking in the sample app
- **Android:**  SnapButtonView responds to volume up events to start capture
- **Android:**  Dialog to update lens group IDs in the sample app
- **Android:**  SnapButtonView re-dispatch touch events to lenses carousel
- **Android:**  Landmarker lenses support
- **iOS:**  Landmarkers support
- **iOS:**  Media picker support


<a name="1.5.11"></a>
## [1.5.11] - 2021-03-17

<a name="1.5.10"></a>
## [1.5.10] - 2021-03-03
### Bug Fixes
- **Android:**  Negotiate MediaCodec supported resolution when video recording


<a name="1.5.9"></a>
## [1.5.9] - 2021-02-26

<a name="1.5.8"></a>
## [1.5.8] - 2021-02-24
### Features
- **Android:**  Expose outputRotationDegrees parameter for photo processing


<a name="1.5.7"></a>
## [1.5.7] - 2021-02-18
### Features
- **Android:**  Better accessibility support


<a name="1.5.6"></a>
## [1.5.6] - 2021-02-03
### Bug Fixes
- **Android:**  Lens Single Tap should work without touch blocking


<a name="1.5.5"></a>
## [1.5.5] - 2021-01-26
### Bug Fixes
- **Android:**  OpenGL memory leak after Session is closed


<a name="1.5.4"></a>
## [1.5.4] - 2021-01-15
### Features
- **Android:**  Expose lens loading overlay configuration


<a name="1.5.3"></a>
## [1.5.3] - 2021-01-06
### Bug Fixes
- **Android:**  Crash when client includes grpc-census library
- **iOS:**  FileHandle exceptions and lens processor crash


<a name="1.5.2"></a>
## [1.5.2] - 2020-12-22
### Bug Fixes
- **Android:**  Fix carousel actions being ignored after re-activation


<a name="1.5.1"></a>
## [1.5.1] - 2020-12-22
### Features
- **Android:**  Add ability to clear ImageProcessor.Output on disconnect


<a name="1.5.0"></a>
## [1.5.0] - 2020-12-03
### Bug Fixes
- **Android:**  Dynamic Plugin class loading is not reliable
- **iOS:**  CarouselView crashing sometimes when swiping

### Features
- **Android:**  Use externally published Plugin interface for dynamic loading
- **iOS:**  Add first frame ready event to processor observer


<a name="1.4.5"></a>
## [1.4.5] - 2020-12-01

<a name="1.4.4"></a>
## [1.4.4] - 2020-11-20

<a name="1.4.3"></a>
## [1.4.3] - 2020-11-18

<a name="1.4.2"></a>
## [1.4.2] - 2020-11-17

<a name="1.4.1"></a>
## [1.4.1] - 2020-11-16
### Bug Fixes
- **Android:**  Dynamic Plugin class loading is not reliable
- **Android:**  Missing lenses carousel center icon
- **Android:**  Better portrait orientation support
- **iOS:**  Lock orientation when recording
- **iOS:**  Carousel sometimes resetting transform on reloading data
- **iOS:**  ARKit video is stretched
- **iOS:**  Image hints are present in videos
- **iOS:**  Some lenses won't download after the internet is back
- **iOS:**  Bundled hints not localizing properly if host app doesn't support localization
- **iOS:**  Recorded video frozen when returning from background

### Features
- **Android:**  Use externally published Plugin interface for dynamic loading
- **Android:**  Customize lenses carousel with custom item positions
- **Android:**  Expose API to disable default camera preview rendering
- **Android:**  Expose lens preview model
- **Android:**  Use exposed lenses carousel API to implement lens button
- **Android:**  Improve dynamic loading sample plugin example
- **Android:**  Camera zoom support example
- **iOS:**  Add LiDAR support
- **iOS:**  Improve AVSessionInput camera performance
- **iOS:**  Expose lens preview model


<a name="1.3.6"></a>
## [1.3.6] - 2020-11-04
### Bug Fixes
- **Android:**  Missing lens placeholder icon
- **Android:**  Better portrait orientation support
- **Android:**  Missing lenses carousel center icon
- **Android:**  Crash when user app targets API level 30 on Android Q (11) devices
- **Android:**  Crash after required permissions accepted
- **iOS:**  Some lenses won't download after the internet is back
- **iOS:**  Race condition sometimes when retrying requests due to no internet
- **iOS:**  Requests sometime failing if app is open for too long
- **iOS:**  Lens repo sometimes returning stale data

### Features
- **Android:**  Added Configuration for Processor to support different input frame rotation behaviors
- **Android:**  Customize lenses carousel with custom item positions and activation flow
- **Android:**  Expose lens preview model
- **Android:**  Improve dynamic loading sample plugin example
- **Android:**  Expose API to disable default camera preview rendering
- **Android:**  Dynamic feature-as-a-plugin example
- **iOS:**  Expose lens preview model


<a name="1.4.0"></a>
## [1.4.0] - 2020-10-28
### Bug Fixes
- **Android:**  Missing lenses carousel center icon
- **Android:**  Better portrait orientation support
- **iOS:**  ARKit video is stretched
- **iOS:**  Image hints are present in videos
- **iOS:**  Some lenses won't download after the internet is back
- **iOS:**  Bundled hints not localizing properly if host app doesn't support localization
- **iOS:**  Recorded video frozen when returning from background

### Features
- **Android:**  Customize lenses carousel with custom item positions
- **Android:**  Expose API to disable default camera preview rendering
- **Android:**  Expose lens preview model
- **Android:**  Use exposed lenses carousel API to implement lens button
- **Android:**  Improve dynamic loading sample plugin example
- **Android:**  Camera zoom support example
- **iOS:**  Add LiDAR support
- **iOS:**  Improve AVSessionInput camera performance
- **iOS:**  Expose lens preview model


<a name="1.3.5"></a>
## [1.3.5] - 2020-10-20
### Bug Fixes
- **Android:**  Missing lenses carousel center icon

### Features
- **Android:**  Customize lenses carousel with custom item positions and activation flow


<a name="1.3.4"></a>
## [1.3.4] - 2020-10-15
### Features
- **Android:**  Expose lens preview model
- **iOS:**  Expose lens preview model


<a name="1.3.3"></a>
## [1.3.3] - 2020-10-15
### Bug Fixes
- **Android:**  Crash when user app targets API level 30 on Android Q (11) devices


<a name="1.3.2"></a>
## [1.3.2] - 2020-10-15

<a name="1.3.1"></a>
## [1.3.1] - 2020-10-09
### Bug Fixes
- **Android:**  Better portrait orientation support
- **Android:**  Crash after required permissions accepted
- **iOS:**  Some lenses won't download after the internet is back
- **iOS:**  Race condition sometimes when retrying requests due to no internet
- **iOS:**  Requests sometime failing if app is open for too long

### Features
- **Android:**  Improve dynamic loading sample plugin example
- **Android:**  Expose API to disable default camera preview rendering
- **Android:**  Dynamic feature-as-a-plugin example


<a name="1.3.0"></a>
## [1.3.0] - 2020-09-25
### Features
- **Android:**  Support photo API captured image processing
- **Android:**  Support dynamic feature loading


<a name="1.2.0"></a>
## [1.2.0] - 2020-08-27
### Bug Fixes
- **Android:**  Processed texture interpolation artifacts when resized
- **Android:**  OpenGL out of memory crash
- **Android:**  Lenses Processor apply callback not invoked

### Features
- **Android:**  Add instrumentation test helpers
- **Android:**  Invalidate metadata cache on cold-start when network is available
- **Android:**  Add ability to check if device is supported
- **Android:**  Reapply lens with launch data if available
- **Android:**  Add x86/x86_64 support
- **Android:**  Progress cycle repeat parameters for SnapButtonView
- **iOS:**  Invalidate metadata cache on cold-start when network is available


<a name="1.1.0"></a>
## [1.1.0] - 2020-07-29
### Features
- **Android:**  Add support for dynamic lens launch data
- **Android:**  Add ability to provide ImageProcessor.Output rotation
- **Android:**  Add post capture preview screen
- **Android:**  Add support to provide user data
- **iOS:**  Add support for dynamic lens launch data
- **iOS:**  Expose user data provider


<a name="1.0.0"></a>
## [1.0.0] - 2020-07-08
### Bug Fixes
- **Android:**  Memory leaks caused by delayed operations
- **Android:**  Handle/abort connection to invalid output surface

### Features
- **Android:**  Offline lens repository support
- **Android:**  Add support for prefetching lenses content
- **Android:**  Add support for lens hints
- **Android:**  Expose Lens vendor data
- **iOS:**  Expose vendor data
- **iOS:**  Add lens prefetcher support
- **iOS:**  Add support for ARKit
- **iOS:**  Add support for localized hints


<a name="0.5.0"></a>
## [0.5.0] - 2020-06-03
### Bug Fixes
- **Android:**  Remove 3rd-party R classes jars from the SDK binary


<a name="0.4.0"></a>
## [0.4.0] - 2020-04-22
### Bug Fixes
- **iOS:**  Original lens should be active on app opening
- **iOS:**  First lens doesn't work on fresh install
- **iOS:**  Carousel in landscape is not aligned
- **iOS:**  Fix carousel ux: close button goes to empty lens

### Features
- **Android:**  Audio processing (analysis and effects) support
- **Android:**  Use lens lifecycle events to update camera UI
- **Android:**  Add support for internal cache configuration
- **Android:**  Integrate SnapButtonView for photo/video capture
- **iOS:**  Add processor observer
- **iOS:**  Add share to Snapchat
- **iOS:**  Capture and image preview support
- **iOS:**  Add support for remote assets and unbundle tracking data
- **iOS:**  Add sample video preview


<a name="0.3.0"></a>
## [0.3.0] - 2020-03-30
### Bug Fixes
- **Android:**  Allow simultaneous touch handling while recording
- **Android:**  Picture/video sharing does not work on Android 10
- **Android:**  Notify lenses list change once network is available
- **iOS:**  Correct effect viewport and aspect ratio for lenses

### Features
- **Android:**  Integrate provided lenses carousel
- **Android:**  Add video/picture capture support
- **iOS:**  Restructure Repository API
- **iOS:**  Add video recording support
- **iOS:**  Add sample UI and migrate CameraViewController to reference UI
- **iOS:**  Add snap camera button
- **iOS:**  Add Carousel


<a name="0.2.0"></a>
## [0.2.0] - 2020-02-27
### Bug Fixes
- **Android:**  Shutdown Camera Kit when app ID is unauthorized
- **Android:**  Restart lens tracking on single tap gesture
- **Android:**  Audio playback continues when app is in background

### Features
- **Android:**  Display loading overlay as lens downloads
- **Android:**  Add support for remote lens metadata and content
- **iOS:**  Add support for remote lens metadata and content


<a name="0.1.0"></a>
## 0.1.0 - 2020-02-12
### Bug Fixes
- **Android:**  Add missing application ID
- **iOS:**  Re-apply lens when entering foreground

### Features
- **Android:**  Add version information to the side menu of sample app
- **Android:**  Save applied lens ID and camera facing in instance state
- **Android:**  Add camera flip button
- **Android:**  Open side drawer on lens button click
- **Android:**  Add next/previous lens buttons to the sample app
- **Android:**  Use Lens name in side bar listing
- **iOS:**  Add Camera Flip Button
- **iOS:**  add prev next buttons to flip between lenses
- **iOS:**  use lens name property
