//  Copyright Snap Inc. All rights reserved.
//  CameraKitSample

import UIKit
import SCSDKCameraKit
import SCSDKCreativeKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SnapchatDelegate {

    private enum Constants {
        static let partnerGroupId = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
    }

    var window: UIWindow?
    fileprivate var supportedOrientations: UIInterfaceOrientationMask = .portrait

    let snapAPI = SCSDKSnapAPI()
    let cameraController = SampleCameraController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        cameraController.groupIDs = [SCCameraKitLensRepositoryBundledGroup, Constants.partnerGroupId]
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .dark
        }

        cameraController.snapchatDelegate = self
        let cameraViewController = CameraViewController(cameraController: cameraController)
        cameraViewController.appOrientationDelegate = self
        window?.rootViewController = cameraViewController
        window?.makeKeyAndVisible()

        return true
    }
    
    func cameraKitViewController(_ viewController: UIViewController, openSnapchat screen: SnapchatScreen) {
        switch screen {
        case .profile, .lens(_):
            // not supported yet in creative kit (1.4.2), should be added in next version
            break
        case .photo(let image):
            let photo = SCSDKSnapPhoto(image: image)
            let content = SCSDKPhotoSnapContent(snapPhoto: photo)
            sendSnapContent(content, viewController: viewController)
        case .video(let url):
            let video = SCSDKSnapVideo(videoUrl: url)
            let content = SCSDKVideoSnapContent(snapVideo: video)
            sendSnapContent(content, viewController: viewController)
        }
    }

    private func sendSnapContent(_ content: SCSDKSnapContent, viewController: UIViewController) {
        viewController.view.isUserInteractionEnabled = false
        snapAPI.startSending(content) { error in
            DispatchQueue.main.async {
                viewController.view.isUserInteractionEnabled = true
            }
            if let error = error {
                print("Failed to send content to Snapchat with error: \(error.localizedDescription)")
                return
            }
        }
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return supportedOrientations
    }
}

// MARK: Helper Orientation Methods

extension AppDelegate: AppOrientationDelegate {

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        supportedOrientations = orientation
    }

    func unlockOrientation() {
        supportedOrientations = .allButUpsideDown
    }

}

// MARK: Data Provider

class SampleCameraController: CameraController {
    override func configureDataProvider() -> DataProviderComponent {
        DataProviderComponent(
            deviceMotion: nil, userData: UserDataProvider(), lensHint: nil, location: nil,
            mediaPicker: lensMediaProvider, remoteApiServiceProviders: [CatFactRemoteApiServiceProvider()])
    }
}
