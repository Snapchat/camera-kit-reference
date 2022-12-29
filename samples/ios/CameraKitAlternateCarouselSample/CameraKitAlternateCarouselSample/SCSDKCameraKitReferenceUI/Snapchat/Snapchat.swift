//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import SCSDKCameraKit
import UIKit

/// Describes the Snapchat screen to open to
public enum SnapchatScreen {
    case profile
    case lens(Lens)
    case photo(UIImage)
    case video(URL)
}

/// CameraKit view controllers will notify this delegate when it needs to open, send info, or interact with Snapchat
public protocol SnapchatDelegate: AnyObject {

    /// CameraKit view controller requests opening Snapchat with specific info
    /// - Parameters:
    ///   - viewController: CameraKit view controller instance
    ///   - screen: Snapchat screen to open to
    func cameraKitViewController(_ viewController: UIViewController, openSnapchat screen: SnapchatScreen)
}
