//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import Foundation

/// Internal helper to deal with resources bundle
public class BundleHelper {
    private enum Constants {
        static let bundleName = "CameraKitReferenceUI"
        static let bundleExtension = "bundle"
    }

    /// Internal helper computed property to get correct resources bundle
    /// (ie. if pods, look for bundle inside main bundle)
    public class var resourcesBundle: Bundle {
        #if SWIFT_PACKAGE
            return .module
        #else
            let bundle = Bundle(for: self)

            guard
                let resourcesUrl = bundle.url(
                    forResource: Constants.bundleName, withExtension: Constants.bundleExtension),
                let resourcesBundle = Bundle(url: resourcesUrl)
            else {
                return bundle
            }

            return resourcesBundle
        #endif
    }
}
