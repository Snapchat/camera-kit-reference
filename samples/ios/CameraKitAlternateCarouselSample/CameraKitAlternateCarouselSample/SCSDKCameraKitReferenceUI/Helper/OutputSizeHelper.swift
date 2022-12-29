//  Copyright Snap Inc. All rights reserved.
//  SCSDKCameraKitReferenceUI

import AVFoundation
import Foundation

/// Provides helper functions to determine output sizes given input sizes and other constraints (aspect ratio, orientation, etc.)
enum OutputSizeHelper {

    /// Returns the size normalized to a new aspect ratio and orientation.
    /// For example, given an input size of 1080x1920 and aspect ratio of 0.462 and portrait orientation,
    /// this will return a new size of 887x1920.
    /// - Parameters:
    ///   - size: The original input size to normalize.
    ///   - aspectRatio: The aspect ratio to normalize the output size to.
    ///   - orientation: The orientation of the input size (defaults to portrait).
    /// - Returns: The new size normalized to the aspect ratio.
    static func normalizedSize(
        for size: CGSize, aspectRatio: CGFloat, orientation: AVCaptureVideoOrientation = .portrait
    ) -> CGSize {
        var height = orientation == .portrait ? size.height : size.width
        var width = orientation == .portrait ? size.width : size.height

        if orientation == .landscapeLeft || orientation == .landscapeRight {
            if height > width * aspectRatio {
                height = width * aspectRatio
            } else {
                width = height / aspectRatio
            }
        } else {
            if width > height * aspectRatio {
                width = height * aspectRatio
            } else {
                height = width / aspectRatio
            }
        }

        return CGSize(width: width, height: height)
    }

}
