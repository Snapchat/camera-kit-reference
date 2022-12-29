//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import UIKit

/// Delegate to receive updates for camera button view
public protocol CameraButtonDelegate: AnyObject {

    /// Called when user taps camera button
    /// - Parameter cameraButton: camera button view
    func cameraButtonTapped(_ cameraButton: CameraButton)

    /// Called when user starts holding down camera button
    /// - Parameter cameraButton: camera button view
    func cameraButtonHoldBegan(_ cameraButton: CameraButton)

    /// Called when user released their hold before the minimum threshold has been reached
    /// - Parameter cameraButton: camera button view
    /// NOTE: this will be followed by a call to cameraButtonTapped(_:)
    func cameraButtonHoldCancelled(_ cameraButton: CameraButton)

    /// Called when user stops holding down camera button
    /// - Parameter cameraButton: camera button view
    func cameraButtonHoldEnded(_ cameraButton: CameraButton)

}

/// Camera ring view for capturing and recording state
public class CameraButton: UIView, UIGestureRecognizerDelegate {
    public enum Constants {
        static let ringSize: CGFloat = 69.0
    }

    // MARK: Properties

    /// Camera button delegate
    public weak var delegate: CameraButtonDelegate?

    /// The minimum time for a hold to be considered "valid."
    /// If the user holds and releases for a duration shorter than specified, the camera button will act as though it has been tapped instead of held.
    public var minimumHoldDuration: TimeInterval = 0.75

    /// Line width for camera ring
    public var ringWidth: CGFloat {
        get {
            return circleOutline.lineWidth
        }
        set {
            circleOutline.lineWidth = newValue
            circleFill.lineWidth = newValue / 1.2
        }
    }

    /// List of allowed gestures to be used when recording a video(LongPressGesture) i.e. Double Tap Gesture, Pinch Gesture.
    public var allowWhileRecording: [UIGestureRecognizer] = []

    /// Ring color while recording
    public var ringColor: UIColor? {
        get {
            return circleFill.strokeColor != nil ? UIColor(cgColor: circleFill.strokeColor!) : nil
        }
        set {
            circleFill.strokeColor = newValue?.cgColor
        }
    }

    /// Tap gesture recognizer that is used to recognize taps on the camera button
    /// to notify delegate that camera button was tapped to trigger an action (ie. capture)
    public private(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognized(_:)))
        gestureRecognizer.delegate = self
        return gestureRecognizer
    }()

    /// Long press gesture recognizer used to handle recording gesture
    /// NOTE: this gets added to superview when the view is added,
    /// so that all touches can be passed through this view
    /// until the gesture is recognized in which it will then eat up all the touches
    public private(set) lazy var pressGestureRecognizer: UILongPressGestureRecognizer = {
        let gestureRecognizer = UILongPressGestureRecognizer(
            target: self, action: #selector(self.longPressGestureRecognized(_:)))
        gestureRecognizer.minimumPressDuration = 0.10
        gestureRecognizer.delegate = self
        return gestureRecognizer
    }()

    // MARK: Views

    /// circle shape for outline of ring
    private let circleOutline: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 6.0

        return layer
    }()

    /// circle shape for fill of ring
    private let circleFill: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor(hex: 0xFFFC00).cgColor
        layer.lineCap = CAShapeLayerLineCap.round
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
        layer.lineWidth = 5.0

        return layer
    }()

    /// The time the hold started
    private var holdStartTime: Date? = nil

    // MARK: Init

    public init() {
        super.init(frame: .zero)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        pressGestureRecognizer.view?.removeGestureRecognizer(pressGestureRecognizer)
        tapGestureRecognizer.view?.removeGestureRecognizer(tapGestureRecognizer)
    }

    private func commonInit() {
        isUserInteractionEnabled = false
        layer.addSublayer(circleOutline)
        layer.addSublayer(circleFill)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let radius = bounds.size.width / 2.0

        let path = UIBezierPath(
            arcCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: CGFloat.pi / -2.0,
            endAngle: 3 * CGFloat.pi / 2.0, clockwise: true)

        circleOutline.path = path.cgPath
        circleFill.path = path.cgPath
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: Constants.ringSize, height: Constants.ringSize)
    }

    // MARK: Gesture Recognizer

    public override func willMove(toSuperview newSuperview: UIView?) {
        pressGestureRecognizer.view?.removeGestureRecognizer(pressGestureRecognizer)
        tapGestureRecognizer.view?.removeGestureRecognizer(tapGestureRecognizer)
        newSuperview?.addGestureRecognizer(pressGestureRecognizer)
        newSuperview?.addGestureRecognizer(tapGestureRecognizer)
        super.willMove(toSuperview: newSuperview)
    }

    @objc private func tapGestureRecognized(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .ended else { return }

        delegate?.cameraButtonTapped(self)
    }

    @objc private func longPressGestureRecognized(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            holdStartTime = Date()
            startRecordingAnimation()
        case .ended, .cancelled, .failed:
            if let holdStartTime = holdStartTime,
                abs(holdStartTime.timeIntervalSinceNow) >= minimumHoldDuration
            {
                // User held for minimum specified threshold
                delegate?.cameraButtonHoldEnded(self)
            } else {
                delegate?.cameraButtonHoldCancelled(self)
                delegate?.cameraButtonTapped(self)
            }

            stopRecordingAnimation()
        case .possible, .changed:
            // pass through
            break
        @unknown default:
            fatalError("unknown new state -- needs to be supported")
        }
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer === pressGestureRecognizer,
            allowWhileRecording.contains(otherGestureRecognizer)
        else {
            return false
        }

        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: self)
        return point.x >= 0 && point.y >= 0 && point.x <= bounds.width && point.y <= bounds.height
    }

    // MARK: Animation

    /// Start animating ring fill
    /// Call this function when gesture recognizer begins
    /// - Parameter ringFillDuration: Duration of ring fill recording animation.
    /// - Parameter maxRecordingDuration: The max duration of a recorded video.
    public func startRecordingAnimation(
        ringFillDuration: TimeInterval = 10.0,
        maxRecordingDuration: TimeInterval = 60.0
    ) {
        delegate?.cameraButtonHoldBegan(self)
        animateOutlineIncrease(duration: Constants.sizeDuration)
        updateRingFillRadius()
        animateOutlineColorFill(duration: Constants.sizeDuration)
        UIView.animate(
            withDuration: Constants.sizeDuration,
            animations: {
                self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
        ) { completed in
            if completed {
                self.animateRingFill(
                    duration: ringFillDuration,
                    repeatCount: Float(maxRecordingDuration / ringFillDuration)
                )
            }
        }
    }

    /// Stop animating ring fill and reset views to original state
    /// Call this function when gesture recognizer ends, cancels, or fails
    public func stopRecordingAnimation() {
        circleFill.removeAnimation(forKey: Constants.fillStrokeKey)
        circleOutline.removeAnimation(forKey: Constants.fillColorKey)
        circleOutline.removeAnimation(forKey: Constants.outlineIncreaseLineWidthKey)
        layer.removeAllAnimations()

        animateOutlineReset(duration: Constants.sizeDuration)
        UIView.animate(withDuration: Constants.sizeDuration) {
            self.transform = .identity
        }
    }

    // MARK: Private Helper

    /// Helper function to animate ring fill
    /// - Parameter duration: Duration of ring fill.
    /// - Parameter repeatCount: The number of times to repeat the ring fill animation.
    private func animateRingFill(duration: TimeInterval, repeatCount: Float) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = duration
        animation.delegate = self
        animation.isRemovedOnCompletion = false
        animation.repeatCount = repeatCount
        circleFill.add(animation, forKey: Constants.fillStrokeKey)
    }

    /// Helper function to animate outline ring fill.
    /// When we transform scale the outline ring needs to fill in with gray.
    /// - Parameter duration: Duration of ring fill.
    private func animateOutlineColorFill(duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "fillColor")
        animation.fromValue = UIColor.clear.cgColor
        animation.toValue = UIColor(hex: 0xd4d4d4).withAlphaComponent(0.5).cgColor
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        circleOutline.add(animation, forKey: Constants.fillColorKey)
    }

    /// Helper function to animate outline line width increase
    /// When we transform scale the view we need to update outline line width
    /// - Parameter duration: duration of line animation
    private func animateOutlineIncrease(duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "lineWidth")
        animation.fromValue = ringWidth
        animation.toValue = ringWidth / 1.2
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        circleOutline.strokeColor = UIColor.clear.cgColor
        circleOutline.add(animation, forKey: Constants.outlineIncreaseLineWidthKey)
    }

    /// Helper function animation outline reset when animation stops
    /// - Parameter duration: duration of line animation
    private func animateOutlineReset(duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "lineWidth")
        animation.fromValue = ringWidth / 1.2
        animation.toValue = ringWidth
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        circleOutline.strokeColor = UIColor.white.cgColor
        circleOutline.add(animation, forKey: Constants.outlineResetLineWidthKey)
    }

    /// Helper function to update recording ring radius to add spacing when recording.
    private func updateRingFillRadius() {
        let recordingRadius = bounds.size.width / 2.0
        let recordingPath = UIBezierPath(
            arcCenter: CGPoint(x: recordingRadius, y: recordingRadius), radius: recordingRadius + 7,
            startAngle: CGFloat.pi / -2.0,
            endAngle: 3 * CGFloat.pi / 2.0, clockwise: true)
        circleFill.path = recordingPath.cgPath
    }
}

extension CameraButton: CAAnimationDelegate {

    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag,
            circleFill.animation(forKey: Constants.fillStrokeKey) === anim
        else {  // guard for finished in case it was removed by `stopRecordingAnimation()`
            return
        }

        // cancel long press
        pressGestureRecognizer.isEnabled = false
        pressGestureRecognizer.isEnabled = true
    }

}

// MARK: Constants

private extension CameraButton.Constants {
    static let fillStrokeKey = "ring_fill_stroke_anim"
    static let fillColorKey = "ring_fill_color_anim"
    static let outlineIncreaseLineWidthKey = "ring_outline_increase_line_width_anim"
    static let outlineResetLineWidthKey = "ring_outline_reset_line_width_anim"
    static let sizeDuration = 0.25
}
