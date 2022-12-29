//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import Foundation
import SCSDKCameraKit

/// Default user data provider to show how to provide user data to CameraKit
public class UserDataProvider: NSObject, SCSDKCameraKit.UserDataProvider {

    /// Delegate for CameraKit to receive updates on user data
    public weak var delegate: UserDataProviderDelegate?

    /// Mocked user data
    public lazy var userData: UserData? = UserData(
        displayName: "Jane Doe", birthDate: formatter.date(from: "1974-05-05"))

    /// Date formatter to formate birth date for user data
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
