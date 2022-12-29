//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import AVFoundation
import AVKit
import SCSDKCameraKit
import UIKit

/// Describes an interface to control app orientation
public protocol AppOrientationDelegate: AnyObject {

    /// Lock app orientation
    /// - Parameter orientation: interface orientation mask to lock orientations to
    func lockOrientation(_ orientation: UIInterfaceOrientationMask)

    /// Unlock orientation
    func unlockOrientation()

}

/// This is the default view controller which handles setting up the camera, lenses, lens picker, etc.
open class CameraViewController: UIViewController, CameraControllerUIDelegate {

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: CameraKit properties

    /// A controller which manages the camera and lenses stack on behalf of the view controller
    public let cameraController: CameraController

    /// App orientation delegate to control app orientation
    public weak var appOrientationDelegate: AppOrientationDelegate?

    /// convenience prop to get current interface orientation of application/scene
    fileprivate var applicationInterfaceOrientation: UIInterfaceOrientation {
        var interfaceOrientation = UIApplication.shared.statusBarOrientation
        if #available(iOS 13, *),
            let sceneOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        {
            interfaceOrientation = sceneOrientation
        }
        return interfaceOrientation
    }

    /// convenience prop to get current interface orientation mask to lock device from rotation
    fileprivate var currentInterfaceOrientationMask: UIInterfaceOrientationMask {
        switch applicationInterfaceOrientation {
        case .portrait, .unknown: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        @unknown default:
            return .portrait
        }
    }

    /// The backing view
    public var cameraView = CameraView()

    /// The lens picker view
    public let lensPickerView = LensPickerView()

    /// Frame size when lens picker view is not open
    public var fullFrameSize = CGRect()

    /// Frame size when lens picker view is open
    public var smallFrameSize = CGRect(x: 0, y: 0, width: 203, height: 362)

    public var isInFullFrame = true

    override open func loadView() {
        view = cameraView
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        setup()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // MARK: Init

    /// Returns a camera view controller initialized with a camera controller that is configured with a newly created AVCaptureSession stack
    /// and CameraKit session with the specified configuration and list of group IDs.
    /// - Parameters:
    ///   - repoGroups: List of group IDs to observe.
    ///   - sessionConfig: Config to configure session with application id and api token.
    ///   Pass this in if you wish to dynamically update or overwrite the application id and api token in the application's `Info.plist`.
    convenience public init(repoGroups: [String], sessionConfig: SessionConfig? = nil) {
        // Max size of lens content cache = 150 * 1024 * 1024 = 150MB
        // 150MB to make sure that some lenses that use large assets such as the ones required for
        // 3D body tracking (https://lensstudio.snapchat.com/templates/object/3d-body-tracking) have
        // enough cache space to fit alongside other lenses.
        let lensesConfig = LensesConfig(cacheConfig: CacheConfig(lensContentMaxSize: 150 * 1024 * 1024))
        let cameraKit = Session(sessionConfig: sessionConfig, lensesConfig: lensesConfig, errorHandler: nil)
        let captureSession = AVCaptureSession()
        self.init(cameraKit: cameraKit, captureSession: captureSession, repoGroups: repoGroups)
    }

    /// Convenience init to configure a camera controller with a specified AVCaptureSession stack, CameraKit, and list of group IDs.
    /// - Parameters:
    ///   - cameraKit: camera kit session
    ///   - captureSession: a backing AVCaptureSession to use
    ///   - repoGroups: the group IDs to observe
    convenience public init(cameraKit: CameraKitProtocol, captureSession: AVCaptureSession, repoGroups: [String]) {
        let cameraController = CameraController(cameraKit: cameraKit, captureSession: captureSession)
        cameraController.groupIDs = repoGroups
        self.init(cameraController: cameraController)
    }

    /// Initialize the view controller with a preconfigured camera controller
    /// - Parameter cameraController: the camera controller to use.
    public init(cameraController: CameraController) {
        self.cameraController = cameraController
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overridable Helper

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cameraController.cameraKit.videoOrientation = videoOrientation(
            from: orientation(from: applicationInterfaceOrientation, transform: coordinator.targetTransform))
    }

    // MARK: Lenses Setup

    /// Apply a specific lens
    /// - Parameters:
    ///   - lens: selected lens
    open func applyLens(_ lens: Lens) {
        cameraView.activityIndicator.stopAnimating()  // stop any loading indicator that may still be going on from previous lens
        cameraController.applyLens(lens) { [weak self] success in
            guard let strongSelf = self else { return }
            if success {
                print("\(lens.name ?? "Unnamed") (\(lens.id)) Applied")

                DispatchQueue.main.async {
                    strongSelf.hideAllHints()
                    strongSelf.cameraView.clearLensView.isHidden = !strongSelf.isInFullFrame
                    strongSelf.cameraView.clearLensView.lensLabel.text = lens.name ?? lens.id
                    if let url = lens.iconUrl {
                        strongSelf.lensPickerView.imageLoader.loadImage(url: url) { [weak self] (image, error) in
                            self?.cameraView.clearLensView.imageView.image = image
                        }
                    }
                }
            }
        }
    }

    /// Helper function to clear currently selected lens
    open func clearLens() {
        cameraView.activityIndicator.stopAnimating()  // stop any loading indicator that may still be going on from current lens
        cameraController.clearLens(completion: nil)
        cameraView.clearLensView.isHidden = true
        cameraView.clearLensView.lensLabel.text = ""
    }

    // MARK: CameraControllerUIDelegate

    open func cameraController(_ controller: CameraController, updatedLenses lenses: [Lens]) {
        lensPickerView.reloadData()
        let selectedItem = lensPickerView.selectedItem

        if !(selectedItem is EmptyItem) {
            lensPickerView.selectItem(selectedItem)
        }
    }

    open func cameraControllerRequestedActivityIndicatorShow(_ controller: CameraController) {
        cameraView.activityIndicator.startAnimating()
    }

    open func cameraControllerRequestedActivityIndicatorHide(_ controller: CameraController) {
        cameraView.activityIndicator.stopAnimating()
    }

    open func cameraControllerRequestedCameraFlip(_ controller: CameraController) {
        flip(sender: controller)
    }

    open func cameraController(
        _ controller: CameraController, requestedHintDisplay hint: String, for lens: Lens, autohide: Bool
    ) {
        guard lens.id == cameraController.currentLens?.id else { return }

        cameraView.hintLabel.text = hint
        cameraView.hintLabel.layer.removeAllAnimations()
        cameraView.hintLabel.alpha = 0.0

        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.cameraView.hintLabel.alpha = 1.0
            }
        ) { completed in
            guard autohide, completed else { return }
            UIView.animate(
                withDuration: 0.5, delay: 2.0,
                animations: {
                    self.cameraView.hintLabel.alpha = 0.0
                }, completion: nil)
        }
    }

    open func cameraController(_ controller: CameraController, requestedHintHideFor lens: Lens) {
        hideAllHints()
    }

    private func hideAllHints() {
        cameraView.hintLabel.layer.removeAllAnimations()
        cameraView.hintLabel.alpha = 0.0
    }

}

// MARK: General Camera Setup

extension CameraViewController {

    /// Calls the relevant setup methods on the camera controller
    fileprivate func setup() {
        cameraView.lensPickerButton.addTarget(self, action: #selector(lensPickerButtonAction), for: .touchUpInside)

        cameraController.configure(
            orientation: videoOrientation(from: applicationInterfaceOrientation),
            textInputContextProvider: TextInputContextProviderImpl(cameraViewController: self),
            agreementsPresentationContextProvider: AgreementsPresentationContextProviderImpl(
                cameraViewController: self), completion: nil)
        setupActions()
        cameraController.cameraKit.add(output: cameraView.previewView)
        cameraController.uiDelegate = self
    }

    /// Configures the target actions and delegates needed for the view controller to function
    fileprivate func setupActions() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(sender:)))
        cameraView.previewView.addGestureRecognizer(singleTap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(flip(sender:)))
        doubleTap.numberOfTapsRequired = 2
        cameraView.previewView.addGestureRecognizer(doubleTap)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(zoom(sender:)))
        cameraView.previewView.addGestureRecognizer(pinchGestureRecognizer)
        cameraView.previewView.automaticallyConfiguresTouchHandler = true

        cameraView.clearLensView.closeButton.addTarget(
            self, action: #selector(self.closeButtonPressed(_:)), for: .touchUpInside)
        cameraView.fullFrameFlipCameraButton.addTarget(
            self, action: #selector(self.flip(sender:)), for: .touchUpInside)
        cameraView.smallFrameFlipCameraButton.addTarget(
            self, action: #selector(self.flip(sender:)), for: .touchUpInside)

        lensPickerView.delegate = self
        lensPickerView.dataSource = self
        lensPickerView.performInitialSelection()

        cameraView.cameraButton.delegate = self
        cameraView.cameraButton.allowWhileRecording = [doubleTap, pinchGestureRecognizer]
    }

}

// MARK: Camera Bottom Bar

extension CameraViewController {

    /// Clears the current lens
    /// - Parameter sender: the caller
    @objc private func closeButtonPressed(_ sender: UIButton) {
        clearLens()
        lensPickerView.selectItem(EmptyItem())
    }

}

// MARK: Single Tap

extension CameraViewController {

    /// Handles a single tap gesture by dismissing the tone map control if it is visible and setting the point
    /// of interest otherwise.
    /// - Parameter sender: The single tap gesture recognizer.
    @objc private func handleSingleTap(sender: UITapGestureRecognizer) {
        setPointOfInterest(sender: sender)
    }

}

// MARK: Camera Point of Interest

extension CameraViewController {

    /// Sets the camera's point of interest for focus and exposure based on where the user tapped
    /// - Parameter sender: the caller
    @objc fileprivate func setPointOfInterest(sender: UITapGestureRecognizer) {
        cameraView.drawTapAnimationView(at: sender.location(in: sender.view))

        guard let focusPoint = sender.captureDevicePoint else { return }

        cameraController.setPointOfInterest(at: focusPoint)
    }

}

// MARK: Camera Flip

extension CameraViewController {

    /// Flips the camera
    /// - Parameter sender: the caller
    @objc fileprivate func flip(sender: Any) {
        cameraController.flipCamera()
        switch cameraController.cameraPosition {
        case .front:
            cameraView.fullFrameFlipCameraButton.accessibilityValue = CameraElements.CameraFlip.front
            cameraView.smallFrameFlipCameraButton.accessibilityValue = CameraElements.CameraFlip.front
        case .back:
            cameraView.fullFrameFlipCameraButton.accessibilityValue = CameraElements.CameraFlip.back
            cameraView.smallFrameFlipCameraButton.accessibilityValue = CameraElements.CameraFlip.back
        default:
            break
        }
    }
}

// MARK: Camera Zoom

extension CameraViewController {

    /// Zooms the camera based on a pinch gesture
    /// - Parameter sender: the caller
    @objc fileprivate func zoom(sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .changed:
            cameraController.zoomExistingLevel(by: sender.scale)
        case .ended:
            cameraController.finalizeZoom()
        default:
            break
        }
    }
}

// MARK: Lens Picker

extension CameraViewController: LensPickerViewControllerDelegate, LensPickerViewDelegate, LensPickerViewDataSource {
    enum Constants {
        static let smallFrameXInset = 86.0
        static let smallFrameYInset = 90.0
        static let smallFrameYPosition = 46.0
    }

    public func lensPickerView(_ view: LensPickerView, didSelect item: LensPickerItem, at index: Int) {
        guard let lens = cameraController.cameraKit.lenses.repository.lens(id: item.lensId, groupID: item.groupId)
        else { return }
        applyLens(lens)

        return
    }

    public func itemsForLensPickerView(_ view: LensPickerView) -> [LensPickerItem] {
        return cameraController.groupIDs.flatMap {
            cameraController.cameraKit.lenses.repository.lenses(groupID: $0).map {
                LensPickerItem(lensId: $0.id, lensName: $0.name, groupId: $0.groupId, imageUrl: $0.iconUrl)
            }
        }
    }

    @objc func lensPickerButtonAction() {
        let vc = LensPickerViewController(lensPickerView: lensPickerView)
        vc.delegate = self
        if #available(iOS 15.0, *) {

            fullFrameSize = cameraView.frame
            let w = UIScreen.main.bounds.width - (Constants.smallFrameXInset * 2)
            let h = UIScreen.main.bounds.height/2 - Constants.smallFrameYInset
            let x = (UIScreen.main.bounds.width - w)/2
            smallFrameSize = CGRect(x: x, y: Constants.smallFrameYPosition, width: w, height: h)

            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.largestUndimmedDetentIdentifier = .medium
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
                sheet.prefersGrabberVisible = true
                sheet.animateChanges {
                    didPresentLensPickerViewController()
                }
            }

            present(vc, animated: true, completion: nil)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true, completion: nil)
        }
    }

    func didPresentLensPickerViewController() {
        if #available(iOS 15.0, *) {
            cameraView.clearLensView.isHidden = true
            cameraView.cameraButton.isHidden = true
            cameraView.lensPickerButton.isHidden = true
            cameraView.snapWatermark.isHidden = true

            UIView.animate(withDuration: 0.3, animations: {
                self.cameraView.frame = self.smallFrameSize
                self.cameraView.previewView.layer.cornerRadius = 12
                self.cameraView.updateFlipButton(isInFullScreen: false)

                self.view.layoutIfNeeded()
            })

            isInFullFrame = false
        }
    }

    func didDismissLensPickerViewController() {
        if #available(iOS 15.0, *) {
            UIView.animate(withDuration: 0.3, animations: {
                self.cameraView.frame = self.fullFrameSize
                self.cameraView.previewView.layer.cornerRadius = 0
                self.cameraView.updateFlipButton(isInFullScreen: true)

                self.view.layoutIfNeeded()
            })

            self.cameraView.clearLensView.isHidden = self.cameraController.currentLens == nil
            self.cameraView.cameraButton.isHidden = false
            self.cameraView.lensPickerButton.isHidden = false
            cameraView.snapWatermark.isHidden = false

            isInFullFrame = true
        }
    }

}

// MARK: Camera Button

extension CameraViewController: CameraButtonDelegate {

    public func cameraButtonTapped(_ cameraButton: CameraButton) {
        print("Camera button tapped")
        cameraController.takePhoto { image, error in
            guard let image = image else { return }
            self.cameraController.clearLens(willReapply: true)
            DispatchQueue.main.async {
                let viewController = ImagePreviewViewController(image: image)
                viewController.presentationController?.delegate = self
                viewController.onDismiss = { [weak self] in
                    self?.cameraController.reapplyCurrentLens()
                }
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }

    public func cameraButtonHoldBegan(_ cameraButton: CameraButton) {
        print("Start recording")
        cameraController.startRecording()
        appOrientationDelegate?.lockOrientation(currentInterfaceOrientationMask)
    }

    public func cameraButtonHoldCancelled(_ cameraButton: CameraButton) {
        cameraController.cancelRecording()
        restoreActiveCameraState()
    }

    public func cameraButtonHoldEnded(_ cameraButton: CameraButton) {
        print("Finish recording")
        cameraController.finishRecording { url, error in
            DispatchQueue.main.async {
                guard let url = url else { return }
                self.cameraController.clearLens(willReapply: true)
                let player = VideoPreviewViewController(videoUrl: url)
                player.presentationController?.delegate = self
                player.onDismiss = { [weak self] in
                    self?.cameraController.reapplyCurrentLens()
                }
                self.present(player, animated: true) {
                    self.restoreActiveCameraState()
                }
            }
        }
    }

    private func restoreActiveCameraState() {
        appOrientationDelegate?.unlockOrientation()
    }

}

// MARK: Presentation Delegate

extension CameraViewController: UIAdaptivePresentationControllerDelegate {

    open func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        guard presentationController.presentedViewController is PreviewViewController else { return }
        cameraController.reapplyCurrentLens()
    }
}

// MARK: Agreements presentation context

extension CameraViewController {

    class AgreementsPresentationContextProviderImpl: NSObject, AgreementsPresentationContextProvider {

        weak var cameraViewController: CameraViewController?

        init(cameraViewController: CameraViewController) {
            self.cameraViewController = cameraViewController
        }

        public var viewControllerForPresentingAgreements: UIViewController {
            return cameraViewController ?? UIApplication.shared.keyWindow!.rootViewController!
        }

        public func dismissAgreementsViewController(_ viewController: UIViewController, accepted: Bool) {
            viewController.dismiss(animated: true, completion: nil)
            if !accepted {
                if cameraViewController?.cameraController.currentLens == nil {
                    cameraViewController?.lensPickerView.selectItem(EmptyItem())
                }
            } else {
                cameraViewController?.lensPickerView.performInitialSelection()
            }
        }

    }

}

// MARK: Text input context

extension CameraViewController {

    class TextInputContextProviderImpl: NSObject, TextInputContextProvider {

        public let keyboardAccessoryProvider: TextInputKeyboardAccessoryProvider? = KeyboardAccessoryViewProvider()
        weak var cameraViewController: CameraViewController?

        init(cameraViewController: CameraViewController) {
            self.cameraViewController = cameraViewController
        }

        public var parentView: UIView? {
            cameraViewController?.view
        }

    }

}

// MARK: Orientation Helper

extension CameraViewController {

    /// Calculates a user interface orientation based on an input orientation and provided affine transform
    /// - Parameters:
    ///   - orientation: the base orientation
    ///   - transform: the transform specified
    /// - Returns: the resulting orientation
    fileprivate func orientation(from orientation: UIInterfaceOrientation, transform: CGAffineTransform)
        -> UIInterfaceOrientation
    {
        let conversionMatrix: [UIInterfaceOrientation] = [
            .portrait, .landscapeLeft, .portraitUpsideDown, .landscapeRight,
        ]
        guard let oldIndex = conversionMatrix.firstIndex(of: orientation), oldIndex != NSNotFound else {
            return .unknown
        }
        let rotationAngle = atan2(transform.b, transform.a)
        var newIndex = Int(oldIndex) - Int(round(rotationAngle / (.pi / 2)))
        while newIndex >= 4 {
            newIndex -= 4
        }
        while newIndex < 0 {
            newIndex += 4
        }
        return conversionMatrix[newIndex]
    }

    /// Determines the applicable AVCaptureVideoOrientation from a given UIInterfaceOrientation
    /// - Parameter interfaceOrientation: the interface orientation
    /// - Returns: the relevant AVCaptureVideoOrientation
    fileprivate func videoOrientation(from interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch interfaceOrientation {
        case .portrait, .unknown: return .portrait
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .portraitUpsideDown: return .portraitUpsideDown
        @unknown default: return .portrait
        }
    }
}
