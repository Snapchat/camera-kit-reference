//  Copyright Snap Inc. All rights reserved.
//  SCSDKCameraKitReferenceUI

import UIKit

/// View that appears when the user taps on the camera view
public class TapAnimationView: UIView {

    private lazy var outerRing: CALayer = {
        let outerRing = CALayer()

        outerRing.borderColor = UIColor.white.cgColor
        outerRing.borderWidth = Constants.outerRingBorderWidth
        outerRing.shadowColor = UIColor.black.cgColor
        outerRing.shadowOpacity = Constants.outerRingShadowOpacity
        outerRing.shadowOffset = CGSize(width: Constants.outerRingShadowOffset, height: Constants.outerRingShadowOffset)
        outerRing.opacity = 0
        outerRing.frame = bounds
        outerRing.cornerRadius = layer.bounds.midX

        return outerRing
    }()

    private lazy var innerCircle: CALayer = {
        let innerCircle = CALayer()

        innerCircle.backgroundColor = UIColor.white.cgColor
        innerCircle.opacity = 0
        innerCircle.frame = bounds.insetBy(dx: Constants.innerCirclePadding, dy: Constants.innerCirclePadding)
        innerCircle.cornerRadius = innerCircle.bounds.midX

        return innerCircle
    }()

    public init(center: CGPoint) {
        super.init(
            frame: CGRect(
                x: center.x - Constants.tapAnimationViewSize / 2,
                y: center.y - Constants.tapAnimationViewSize / 2,
                width: Constants.tapAnimationViewSize,
                height: Constants.tapAnimationViewSize
            ))

        accessibilityIdentifier = OtherElements.tapToFocusView.id
        isUserInteractionEnabled = false
        [outerRing, innerCircle].forEach(layer.addSublayer)
    }

    /// Performs the tap animation and removes the view upon completion of the animation
    public func show() {
        outerRing.removeAllAnimations()
        innerCircle.removeAllAnimations()

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.fadeOutView()
        }

        addOuterRingOpacityAnimation()
        addOuterRingScaleAnimation()
        addInnerCircleOpacityAnimation()
        addInnerCircleScaleAnimation()

        CATransaction.commit()
    }

    private func fadeOutView() {
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.removeFromSuperview()
        }

        let animation = CABasicAnimation(keyPath: Constants.opacityAnimationKey)
        animation.duration = Constants.animationStepDuration
        animation.toValue = NSNumber(floatLiteral: 0.0)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        outerRing.add(animation, forKey: Constants.exposureAnimationKey)

        CATransaction.commit()
    }

    private func keyFrameAnimation(
        with keyPath: String,
        duration: CGFloat,
        values: [Any],
        keyTimes: [NSNumber],
        timingfunctions: [CAMediaTimingFunction]
    ) -> CAKeyframeAnimation {
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: keyPath)
        keyFrameAnimation.duration = duration
        keyFrameAnimation.values = values
        keyFrameAnimation.keyTimes = keyTimes
        keyFrameAnimation.timingFunctions = timingfunctions
        keyFrameAnimation.fillMode = .forwards
        keyFrameAnimation.isRemovedOnCompletion = false

        return keyFrameAnimation
    }

    private func animation(
        with keyPath: String,
        duration: CGFloat,
        fromValue: Any,
        toValue: Any,
        timingFunction: CAMediaTimingFunction
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.timingFunction = timingFunction
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        return animation
    }

    private func addOuterRingOpacityAnimation() {
        let animation = keyFrameAnimation(
            with: "opacity",
            duration: Constants.animationStepDuration * 5,
            values: [0.0, 1.0, 1.0, 0.0],
            keyTimes: [0.0, 0.2, 0.8, 1.0],
            timingfunctions: [
                CAMediaTimingFunction(controlPoints: 0.0, 0.0, 0.0, 1.0),
                CAMediaTimingFunction(name: .linear),
                CAMediaTimingFunction(name: .easeInEaseOut),
            ]
        )

        outerRing.add(animation, forKey: Constants.opacityAnimationKey)
    }

    private func addOuterRingScaleAnimation() {
        let animation = keyFrameAnimation(
            with: "transform",
            duration: Constants.animationStepDuration * 3,
            values: [
                NSValue(caTransform3D: CATransform3DMakeScale(0.50, 0.50, 1.0)),
                NSValue(caTransform3D: CATransform3DIdentity),
                NSValue(caTransform3D: CATransform3DMakeScale(0.83, 0.83, 1.0)),
            ],
            keyTimes: [0.0, 0.66, 1.0],
            timingfunctions: [
                CAMediaTimingFunction(controlPoints: 0.0, 0.0, 0.0, 1.0),
                CAMediaTimingFunction(name: .easeInEaseOut),
            ])

        outerRing.add(animation, forKey: Constants.scaleAnimationKey)
    }

    private func addInnerCircleOpacityAnimation() {
        let animation = keyFrameAnimation(
            with: "opacity",
            duration: Constants.animationStepDuration * 3,
            values: [0.0, 0.4, 0.0],
            keyTimes: [0.0, 0.33, 1.0],
            timingfunctions: [
                CAMediaTimingFunction(name: .easeIn),
                CAMediaTimingFunction(name: .easeInEaseOut),
            ]
        )

        innerCircle.add(animation, forKey: Constants.opacityAnimationKey)
    }

    private func addInnerCircleScaleAnimation() {
        let animation = animation(
            with: "transform",
            duration: Constants.animationStepDuration * 2,
            fromValue: NSValue(caTransform3D: CATransform3DMakeScale(0.0, 0.0, 1.0)),
            toValue: CATransform3DIdentity,
            timingFunction: CAMediaTimingFunction(controlPoints: 0.0, 0.0, 0.0, 1.0))

        innerCircle.add(animation, forKey: Constants.scaleAnimationKey)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Constants

extension TapAnimationView {

    fileprivate enum Constants {
        static let animationStepDuration: TimeInterval = 0.167

        static let innerCirclePadding: CGFloat = 2.5

        static let outerRingShadowOpacity: Float = 0.4
        static let outerRingBorderWidth: CGFloat = 1.0
        static let outerRingShadowOffset: CGFloat = 0.5

        static let tapAnimationViewSize: CGFloat = 56.0

        static let opacityAnimationKey = "opacity"
        static let scaleAnimationKey = "scale"
        static let exposureAnimationKey = "exposure"
    }

}
