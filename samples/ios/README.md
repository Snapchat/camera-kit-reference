# Camera Kit iOS

### Usage Philosophy

In general, Camera Kit attaches to your existing camera workflow. You are still responsible for configuring and managing an AVCaptureSession, which Camera Kit will attach onto. You may start, stop, and reconfigure your session as needed.

## Getting Started

### Requirements

Camera Kit requires a minimum of iOS 12, and a 64 bit processor. Camera Kit will compile, but not run on a Simulator (due to lack of AVCaptureSession support).

Make sure you also update `SCCameraKitAPIToken` in your application's `Info.plist` with the API token from the Snap Kit developer portal. Note that you can also pass in these values when creating a session like:
```swift
let sessionConfig = SessionConfig(apiToken: "api_token_here")
let session = Session(sessionConfig: sessionConfig, lensesConfig: nil, errorHandler: nil)
```
This is useful in case you need to dynamically update your API token which may happen in the case where your API token gets revoked for some reason.

In order to test sharing to Snapchat, make sure you also add your Snap Kit client id `SCSDKClientId` in `Info.plist`

### Dependency Management

Camera Kit currently supports CocoaPods.

#### CocoaPods

Add

```
pod 'SCCameraKitReferenceUI'
```

to your `Podfile`. If your application uses SwiftUI, you can use our SwiftUI SDK below

```
pod 'SCCameraKit'
pod 'SCCameraKitReferenceSwiftUI'
```

Before opening the workspace make sure you run

```
pod install
```

and open `CameraKitSample.xcworkspace`.

#### Configure your AVCaptureSession Pipeline

First, create and configure an AVCaptureSession. Apple provides a full-featured [reference](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/setting_up_a_capture_session).

For example, if you want to setup a regular capture session for the front facing camera you'd do:
```swift
let captureSession = AVCaptureSession()
captureSession.beginConfiguration()
guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
    let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
    captureSession.canAddInput(videoDeviceInput) else { return }
captureSession.addInput(videoDeviceInput)
captureSession.commitConfiguration()
captureSession.startRunning()
```

(PS: don't forget to add `NSCameraUsageDescription` in your Info.plist and make sure you have set up the proper permissions/authorization flows)

#### Configuring the Camera Kit Pipeline

Camera Kit works similarly to AVCaptureSession – it also has inputs and outputs. We'll create a Camera Kit session, and connect it to your existing AVCaptureSession.

To begin, first instantiate a `Session`. A `Session` object will be your main entry point into Camera Kit. Through it, you can access components like lenses.

```swift
let cameraKit = Session()
```

Next, create a Camera Kit input and start your Camera Kit Session with it. AVSessionInput is an input that Camera Kit provides that wraps up lens-specific details of AVCaptureSession configuration (such as setting the pixel format).

```swift
let input = AVSessionInput(session: yourAVCaptureSession)
cameraKit.start(with: input)
```

To display the processed output of Camera Kit, we provide a `PreviewView` that behaves similarly to `AVCaptureVideoPreviewLayer`. The `PreviewView` is a Camera Kit `Output` – it receives processed frames and displays them. We'll also set `automaticallyConfiguresTouchHandler` so that Camera Kit can process touch events and users can interact with lenses. Add it to the view heirarchy like any other `UIView`, and connect it to the Session by calling `add(output:)`.

```swift
let previewView = PreviewView()
previewView.automaticallyConfiguresTouchHandler = true
cameraKit.add(output: previewView)
```

At this point, if you build and run your app, you should see your camera input displaying onscreen without any lenses applied to it. We'll discuss how to activate lenses in the next section.

#### Activating Lenses

Camera Kit lenses are provided by the `LensRepository` class. You can access this through `cameraKit.lenses.respository`. Lenses are fetched asynchronously by adding yourself as an observer for a specific groupID and/or lensID in the repository, and you may wish to hold a reference to the lenses returned from `LensRepository`.

```swift
func repository(_ repository: LensRepository, didUpdateLenses lenses: [Lens], forGroupID groupID: String) {
	self.lenses = lenses
}

cameraKit.lenses.repository.addObserver(self, groupID: "group_id_here")
```

The `LensProcessor` is responsible for applying and clearing lenses. You can access it through `cameraKit.lenses.processor`.

We can now take the lens that we've retrieved from the repository, and apply it to the lens processor.

```swift
cameraKit.lenses.processor?.apply { success in
	// If success == true, the lens is now applied
}
```

The preview view should now be showing camera input with a lens applied.

When you are done with a lens and want to remove it from the camera input, you can call `clear` on the lens processor. It is _not_ neccessary to clear a lens before applying a new one.

```swift
cameraKit.lenses.processor?.clear() { success in
	// If success == true, the lens has been cleared
}
```

The preview view should once again be showing camera input with no lenses applied.

### Samples
This directory includes sample apps that demonstrate different approaches to integrating the Camera Kit SDK:
- [CameraKitSample](./CameraKitSample) contains a fully functioning camera capture with lenses and preview flow.
- [CameraKitAlternateCarouselSample](./CameraKitAlternateCarouselSample) demonstrates how to build your own carousel and preview screen.

### How to Support `SceneDelegate`
For applications that are deployed to iOS 13 and up, please see [How to Support `SceneDelegate`](./SceneDelegate.md) for information to support the modern `SceneDelegate` life-cycle.

### Push To Device (P2D)
Applications can receive lenses from Lens Studio using the P2D feature. See [P2D Integration](./P2D.md).
