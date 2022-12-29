//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import UIKit

/// This is the lens picker item view model which represents a specific lens icon
public class LensPickerItem: Identifiable, Equatable {

    /// id for lens picker item
    public let id: String

    /// lens id
    public let lensId: String

    /// lens name
    public let lensName: String?

    /// group id lens belongs to
    public let groupId: String

    /// image url for lens icon
    public let imageUrl: URL?

    /// downloaded image for lens icon
    public var image: UIImage?

    /// Designated init for a lens picker item
    /// - Parameters:
    ///   - lensId: lens id
    ///   - groupId: group id that lens belongs to
    ///   - imageUrl: optional image url of lens icon
    ///   - image: optional loaded UIImage of icon
    public init(lensId: String, lensName: String?, groupId: String, imageUrl: URL? = nil, image: UIImage? = nil) {
        self.id = lensId + groupId
        self.lensId = lensId
        self.lensName = lensName
        self.groupId = groupId
        self.imageUrl = imageUrl
        self.image = image
    }

    static public func == (lhs: LensPickerItem, rhs: LensPickerItem) -> Bool {
        lhs.id == rhs.id
    }

}

/// Concrete class for an empty item (clear camera button)
public class EmptyItem: LensPickerItem {
    public init() {
        super.init(
            lensId: "empty",
            lensName: "empty",
            groupId: "empty",
            imageUrl: nil,
            image: UIImage(named: "ck_lens_empty", in: BundleHelper.resourcesBundle, compatibleWith: nil))
    }
}

