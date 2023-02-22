# How to Support `SceneDelegate`

Apple introduced `SceneDelegate` in iOS 13. This class can respond to state transitions of a `Scene` or an app's UI, e.g. entering foreground or background. See Apple's [documentation](https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle) for setting up the environment to launch from Scenes. Please note: setting up Camera Kit from `AppDelegate` when launching from scenes can lead to unexpected behavior, such as camera failing to appear.

The Camera Kit iOS sample apps do not currently demonstrate how this can be achieved. We intend to update them in a future release. In the meantime, here is some documentation to help you achieve that.

If your app has a `SceneDelegate` then do your set up there (rather than the `AppDelegate`) by adding the following code:

```swift
import UIKit
import SCSDKCameraKit
import SCSDKCameraKitReferenceUI

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private enum Constants {
        static let partnerGroupId = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
    }
    
    var window: UIWindow?
    let cameraController = CameraController()


    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: UIScreen.main.bounds)
        
        cameraController.groupIDs = [SCCameraKitLensRepositoryBundledGroup, Constants.partnerGroupId]
        
        let cameraViewController = CameraViewController(cameraController: cameraController)
      
        window?.rootViewController = cameraViewController
        window?.windowScene = scene
        window?.makeKeyAndVisible()
    }
}
```

If you would like to support Scenes on iOS 13+, this is all you need to do.

Remember, however, that iOS 12 does not support Scenes. What if you would like your app to deploy a `SceneDelegate` but also support iOS 12? In that case, you can setup Camera Kit conditionally: do Camera Kit setup in `SceneDelegate` for iOS 13+ and in `AppDelegate` for iOS 12.

```swift
import UIKit
import SCSDKCameraKit
import SCSDKCameraKitReferenceUI

extension UIApplication {
    var supportsScenes: Bool {
        if #available(iOS 13, *),
           Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") != nil {
            return true
        }
        return false
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private enum Constants {
        static let partnerGroupId = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
    }

    var window: UIWindow?
    let cameraController = CameraController()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if application.supportsScenes {
            // Do nothing here because Camera Kit setup happens in SceneDelegate
            return true
        }
        window = UIWindow(frame: UIScreen.main.bounds)
        
        cameraController.groupIDs = [SCCameraKitLensRepositoryBundledGroup, Constants.partnerGroupId]
        
        let cameraViewController = CustomizedCameraViewController(cameraController: cameraController)

        window?.rootViewController = cameraViewController
        window?.makeKeyAndVisible()

        return true
    }
}
```
