//  Copyright Snap Inc. All rights reserved.
//  CameraKitSample

import Foundation

struct ApplicationInfo {
    private struct Constants {
        static let buildKey = "CFBundleVersion"
        static let versionKey = "CFBundleShortVersionString"
    }
    
    static var build: String? {
        return Bundle.main.infoDictionary?[Constants.buildKey] as? String
    }
    
    static var version: String? {
        return Bundle.main.infoDictionary?[Constants.versionKey] as? String
    }
}
