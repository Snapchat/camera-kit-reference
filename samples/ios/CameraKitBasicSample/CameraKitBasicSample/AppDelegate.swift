import UIKit
import SCSDKCameraKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = CameraViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}

