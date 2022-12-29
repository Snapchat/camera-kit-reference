//  Copyright Snap Inc. All rights reserved.
//  SCSDKCameraKitReferenceUI

import Foundation
import UIKit

extension UITapGestureRecognizer {
    /// Converts a point in a view to the coordinate system used by AVCaptureDevice
    /// AVCaptureDevice uses a coordinate system where (0, 0) is the top left and (1.0, 1.0) is the bottom right if the device
    /// is in landscape orientation with the home button on the right
    var captureDevicePoint: CGPoint? {
        guard let view = view else { return nil }

        var interfaceOrientation = UIApplication.shared.statusBarOrientation
        if #available(iOS 13, *),
            let sceneOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        {
            interfaceOrientation = sceneOrientation
        }

        let tapPoint = location(in: view)

        switch interfaceOrientation {
        case .portrait:
            return CGPoint(
                x: tapPoint.y / view.bounds.size.height,
                y: 1.0 - (tapPoint.x / view.bounds.size.width)
            )
        case .portraitUpsideDown:
            return CGPoint(
                x: 1.0 - (tapPoint.y / view.bounds.size.height),
                y: tapPoint.x / view.bounds.size.width
            )
        case .landscapeRight:
            return CGPoint(
                x: tapPoint.x / view.bounds.size.width,
                y: tapPoint.y / view.bounds.size.height
            )
        case .landscapeLeft:
            return CGPoint(
                x: 1.0 - (tapPoint.x / view.bounds.size.width),
                y: 1.0 - (tapPoint.y / view.bounds.size.height)
            )
        default: return nil
        }
    }
}
