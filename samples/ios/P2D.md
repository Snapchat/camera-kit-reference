# Integrating Push to Device on iOS

### Note on Shipping Push to Device

Push to Device is intended only for lens development. You should not submit this feature with your production app. Many of the steps listed below describe steps you can use to ensure that Push to Device is only built in debug configurations.

### Define a build configuration in your project

In Xcode, add `-DCAMERAKIT_PUSHTODEVICE` to `Other Swift Flags`'s `Debug` configuration. 

### Add yourself to demo testers

Ensure that you are part of the group of demo testers on the app from the developer portal.

- Go to Snap Kit Developer Portal [for your specific app](https://kit.snapchat.com/manage/apps/)
- Go to the Demo Users section
- Add your Snapchat username

### Install Pods for Push To Device

Four frameworks are required for Push To Device. The frameworks are bundled in with the Camera Kit distribution folder. To use them make the following changes to your Podfile:

```swift
target 'Your-App-Name' do
...
  pod 'SCCameraKitLoginKitAuth', :path => 'CameraKit/CameraKitLoginKitAuth', :configurations => ['Debug']
  pod 'SCCameraKitBaseExtension', :path => 'CameraKit/CameraKitBaseExtension/', :configurations => ['Debug']
  pod 'SCCameraKitPushToDeviceExtension', :path => 'CameraKit/CameraKitPushToDeviceExtension/', :configurations => ['Debug']
...
```

If you're using the CameraKit Reference UI, you need to configure your pods to include the `CAMERAKIT_PUSHTODEVICE` flag. You can see how to do this in the sample app's Podfile.

Change the target name to the name of your app. In your project directory, run the following terminal command:

```shell
pod install
```

### Add the scope in your Application's Info.plist

```xml
<key>SCSDKScopes</key>
    <array>
        <string>https://auth.snapchat.com/oauth2/api/camkit_lens_push_to_device</string>
    </array>
```

### Add the URL scheme in your Application's Info.plist

```xml
<key>CFBundleURLSchemes</key>
    <string></string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>your-app-name</string>
            </array>
        </dict>
    </array>
```

### Add a callback url using the URL scheme defined above

```xml
<key>SCSDKRedirectUrl</key>
<string>your-app-name://snap-kit/oauth2</string>
```

### Update the AppDelegate to handle the callback defined above like this

```swift
#if CAMERAKIT_PUSHTODEVICE
import SCSDKLoginKit
#endif
...
    func application(
       _ app: UIApplication,
       open url: URL,
       options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

...
      if SCSDKLoginClient.application(app, open: url, options: options) {
            return true
      }
```

### Create an instance of a LoginKitTokenProvider

```swift
import SCSDKCameraKitLoginKitAuth
...
    let tokenProvider = LoginKitAccessTokenProvider()
```

### Update your CameraController's groupIDs to include SCSDKCameraKitPushToDeviceExtension.SCCameraKitPushToDeviceGroupID

```swift

#if CAMERAKIT_PUSHTODEVICE
cameraController.groupIDs = [SCSDKCameraKitPushToDeviceExtension.SCCameraKitPushToDeviceGroupID]
#endif

```

### Create an instance of a PushToDevice object and set its delegate and initiate pairing

```swift

#if CAMERAKIT_PUSHTODEVICE
import SCSDKCameraKitPushToDeviceExtension

pushToDevice = PushToDevice(
  cameraKitSession: cameraController.cameraKit,
  tokenProvider: tokenProvider
)

pushToDevice.delegate = self
#endif
...
// Consider having a debug only UIButton or UIGestureRecognizer which, upon press, calls the following
pushToDevice.initiatePairing()

```

From a user perspective you will see a login flow. If Snapchat is installed this will be handled in app, if not, Safari will open and the user will be asked to log in there. Once logged in, the `PushToDeviceDelegate` methods will be called. This delegation is mostly for informational purposes but it is important to understand when certain events take place as there is some amount of user interaction that must take place. The following are a few of the methods that will be called throughout the Push To Device journey.

### Upon successful authentication

```swift
func pushToDeviceDidAcquireAuthToken(_ pushToDevice: PushToDeviceProtocol) {
  ...
}
```

It is up to the user/developer to point their camera at a Lens Studio provided Snapcode.

### Upon successful scanning of the Snapcode

```swift
func pushToDeviceDidScanSnapcode(_ pushToDevice: PushToDeviceProtocol) {
   ...
}
```

At this point the scan has completed and the user/developer may stop pointing their camera at the Snapcode.

### Upon successful pairing between Lens Studio, Snapchat, and this device

```swift
func pushToDeviceComplete(_ pushToDevice: PushToDeviceProtocol) {
    ...
}
```

At this point the connection has been made, the User/Developer should now press the "Send to Snapchat" button in Lens Studio

### Successfully pushed a lens to this device

```swift
func didApplyLens(_ pushToDevice: PushToDeviceProtocol) {
   ...
}
```

At this point the flow is complete and a lens should be augmenting your reality.

