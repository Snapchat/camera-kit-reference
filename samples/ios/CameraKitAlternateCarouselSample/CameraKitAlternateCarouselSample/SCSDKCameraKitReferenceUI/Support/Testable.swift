//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import Foundation

/// Describes an element that can be UI tested
public protocol TestableElement {

    /// identifier for the testable element
    var id: String { get }
}

public extension TestableElement where Self: RawRepresentable {
    var id: String {
        return "\(String(describing: type(of: self)))_\(rawValue)"
    }
}

// MARK: Camera Clear Lens

/// ClearLens view testable elements
public enum ClearLensElements: String, TestableElement {
    case closeButton
}

// MARK: Camera View

/// CameraViewController testable elements
public enum CameraElements: String, TestableElement {
    case lensLabel
    case flipCameraButton
    case photoLibraryButton
    case cameraButton
    case lensPickerButton
}

public extension CameraElements {

    enum CameraFlip {
        static public let front = "front"
        static public let back = "back"
    }

}

// MARK: Lens Picker

/// LensPickerView testable elements
public enum LensPickerElements: String, TestableElement {
    case collectionView
    case lensCell
}

// MARK: Preview

/// PreviewViewController testable elements
public enum PreviewElements: String, TestableElement {
    case closeButton, shareButton, imageView, playerControllerView
}

// MARK: Other Elements

/// Other misc testable elements
public enum OtherElements: String, TestableElement {
    case tapToFocusView
}
