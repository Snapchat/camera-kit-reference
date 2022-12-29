//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import ARKit
import AVFoundation
import AVKit
import SCSDKCameraKit
import UIKit

public protocol CameraControllerUIDelegate: AnyObject {

    /// Notifies the delegate that the camera controller has resolved a new list of available lenses
    /// - Parameters:
    ///   - controller: The camera controller.
    ///   - lenses: The newly available lenses.
    func cameraController(_ controller: CameraController, updatedLenses lenses: [Lens])

    /// Notifies the delegate that the camera controller is currently in a loading state, and an activity indicator should be displayed.
    /// - Parameter controller: The camera controller.
    func cameraControllerRequestedActivityIndicatorShow(_ controller: CameraController)

    /// Notifies the delegate that the camera controller is no longer in a loading state, and an activity indicator should be hidden.
    /// - Parameter controller: The camera controller.
    func cameraControllerRequestedActivityIndicatorHide(_ controller: CameraController)

    /// Notifies the delegate that the camera position should be flipped.
    /// - Parameter controller: The camera controller.
    func cameraControllerRequestedCameraFlip(_ controller: CameraController)

    /// Notifies the delegate that a lens has requested that a hint should be displayed
    /// - Parameters:
    ///   - controller: The camera controller.
    ///   - hint: The hint text that should be displayed.
    ///   - lens: The requesting lens.
    ///   - autohide: Whether or not the hint should be automatically hidden, after a callee-determined amount of time.
    func cameraController(
        _ controller: CameraController, requestedHintDisplay hint: String, for lens: Lens, autohide: Bool)

    /// Notifies the delegate that any hints requested by the specified lens should be hidden
    /// - Parameters:
    ///   - controller: The camera controller.
    ///   - lens: The lens whose hints should be hidden.
    func cameraController(_ controller: CameraController, requestedHintHideFor lens: Lens)

}

// MARK: Class Definition and State

/// A controller which manages the camera and lenses stack on behalf of its owner
open class CameraController: NSObject, LensRepositoryGroupObserver, LensPrefetcherObserver, LensHintDelegate {

    // MARK: - Public API

    // MARK: Public vars

    /// A capture session we'll use for camera input.
    public let captureSession: AVCaptureSession

    /// The CameraKit session
    public let cameraKit: CameraKitProtocol

    /// The position of the camera.
    public private(set) var cameraPosition: AVCaptureDevice.Position = .front {
        didSet {
            cameraKit.cameraPosition = cameraPosition
        }
    }

    // MARK: Outputs

    /// An output used for taking still photos.
    public private(set) var photoCaptureOutput: PhotoCaptureOutput?

    /// An output used for recording videos.
    public private(set) var recorder: Recorder?

    // MARK: Data providers

    /// Media provider for CameraKit.
    public let lensMediaProvider = LensMediaPickerProviderPhotoLibrary(defaultAssetTypes: [.image, .imageCroppedToFace])

    // MARK: Delegates

    /// Snapchat delegate for requests to open the main Snapchat app.
    public weak var snapchatDelegate: SnapchatDelegate?

    /// Delegate for responding to UI requests from camera controller.
    public weak var uiDelegate: CameraControllerUIDelegate?

    // MARK: State

    /// The currently selected and active lens.
    public private(set) var currentLens: Lens?

    /// List of lens repository groups to observe/show in lens picker
    public var groupIDs: [String] = [] {
        didSet {
            let removedIDs = Set(oldValue).subtracting(groupIDs)
            let addedIDs = Set(groupIDs).subtracting(oldValue)
            for group in removedIDs {
                cameraKit.lenses.repository.removeObserver(self, groupID: group)
            }
            for group in addedIDs {
                cameraKit.lenses.repository.addObserver(self, groupID: group)
            }
            // you can also observe a single lens in a group if you only care about a specific lens
            // cameraKit.lenses.repository.cameraKit.lenses.repository.addObserver(self, specificLensID: "123", groupID: "1")
            // and then get the lens after by calling
            // cameraKit.lenses.repository.lens(id: "123", groupID: "1");
        }
    }

    // MARK: Initializers

    /// Returns a camera controller that is initialized with a newly created AVCaptureSession stack
    /// and CameraKit session with the specified configuration and list of group IDs.
    /// - Parameter sessionConfig: Config to configure session with application id and api token.
    /// Pass this in if you wish to dynamically update or overwrite the application id and api token in the application's `Info.plist`.
    public convenience init(sessionConfig: SessionConfig? = nil) {
        // this is how you configure properties for a CameraKit Session
        // max size of lens content cache = 150 * 1024 * 1024 = 150MB
        // 150MB to make sure that some lenses that use large assets such as the ones required for
        // 3D body tracking (https://lensstudio.snapchat.com/templates/object/3d-body-tracking) have
        // enough cache space to fit alongside other lenses.
        let lensesConfig = LensesConfig(cacheConfig: CacheConfig(lensContentMaxSize: 150 * 1024 * 1024))
        let cameraKit = Session(sessionConfig: sessionConfig, lensesConfig: lensesConfig, errorHandler: nil)
        let captureSession = AVCaptureSession()
        self.init(cameraKit: cameraKit, captureSession: captureSession)
    }

    /// Init with camera kit session, capture session, and lens holder
    /// - Parameters:
    ///   - cameraKit: camera kit session
    ///   - captureSession: avcapturesession
    public init(cameraKit: CameraKitProtocol, captureSession: AVCaptureSession) {
        self.cameraKit = cameraKit
        self.captureSession = captureSession
        super.init()
    }

    // MARK: Configuration

    /// Configures the overall camera and lenses stack.
    /// - Parameters:
    ///   - orientation: the orientation
    ///   - completion:  a nullable completion that is called after configuration is done.
    ///                  In case it's a first app start (when camera permission is not determined yet) a completion will be called after the prompt.
    public func configure(
        orientation: AVCaptureVideoOrientation,
        textInputContextProvider: TextInputContextProvider?,
        agreementsPresentationContextProvider: AgreementsPresentationContextProvider?,
        completion: (() -> Void)?
    ) {
        configureNotifications()
        promptForAccessIfNeeded { [self] in
            configureCaptureSession()
            configurePhotoCapture()
            configureLenses(
                orientation: orientation,
                textInputContextProvider: textInputContextProvider,
                agreementsPresentationContextProvider: agreementsPresentationContextProvider)
            completion?()
        }
    }

    /// Configures the lenses pipeline.
    /// - Parameter orientation: the camera orientation.
    open func configureLenses(
        orientation: AVCaptureVideoOrientation,
        textInputContextProvider: TextInputContextProvider?,
        agreementsPresentationContextProvider: AgreementsPresentationContextProvider?
    ) {
        // Create a CameraKit input. AVSessionInput is an input that CameraKit provides that wraps up lens-specific
        // details of AVCaptureSession configuration (such as setting the pixel format).
        // You are still responsible for normal configuration of the session (adding the AVCaptureDevice, etc).
        let input = AVSessionInput(session: captureSession)

        // Create a CameraKit ARKit input. AVSessionInput is an input that CameraKit provides that wraps up lens-specific
        // details of ARSession configuration.
        let arInput = ARSessionInput()

        // Start the actual CameraKit session. Once the session is started, CameraKit will begin processing frames and
        // sending output. The lens processor (cameraKit.lenses.processor) will be instantiated at this point, and
        // you can start sending commands to it (such as applying/clearing lenses).
        cameraKit.start(
            input: input,
            arInput: arInput,
            cameraPosition: .front,
            videoOrientation: orientation,
            dataProvider: configureDataProvider(),
            hintDelegate: self,
            textInputContextProvider: textInputContextProvider,
            agreementsPresentationContextProvider: agreementsPresentationContextProvider
        )

        // Start the capture session. It's important you start the capture session after starting the CameraKit session
        // because the CameraKit input and session configures the capture session implicitly and you may run into a
        // race condition which causes some audio and video output frames to be lost, resulting in a blank preview view
        input.startRunning()

        cameraKit.presentAgreementsImmediately()
    }

    /// Configures the data provider for lenses. Subclasses may override this to customize their data provider.
    /// - Returns: a configured data provider.
    open func configureDataProvider() -> DataProviderComponent {
        // By default, CameraKit will handle data providers (such as device motion),
        // but if you want to handle specific data provider(s), pass them in here, example:
        DataProviderComponent(
            deviceMotion: nil, userData: UserDataProvider(), lensHint: nil, location: nil,
            mediaPicker: lensMediaProvider)
    }

    // MARK: Camera Control

    /// Zoom in by a given factor from whatever the current zoom level is
    /// - Parameter factor: the factor to zoom by.
    /// - Note: the zoom level will be capped to a minimum level of 1.0.
    public func zoomExistingLevel(by factor: CGFloat) {
        zoomLevel = max(1, lastZoomLevel * factor)
    }

    /// Save whatever the current zoom level is.
    public func finalizeZoom() {
        lastZoomLevel = zoomLevel
    }

    /// Flips the camera to the other side
    public func flipCamera() {
        cameraPosition = cameraPosition == .front ? .back : .front
    }

    /// Options to support when setting a point of interest
    public struct PointOfInterestOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        // Option to enable rebalancing exposure when setting the camera's point of interest
        public static let exposure = PointOfInterestOptions(rawValue: 1 << 0)

        // Option to enable refocusing the camera when setting the camera's point of interest
        public static let focus = PointOfInterestOptions(rawValue: 1 << 1)
    }

    /// Sets camera point of interest for operations in the option set. Also adds observers for the current device such
    /// that once the focusing/exposure rebalancing operations are complete, continuous autofocus/autoexposure
    /// are restored (see observeValue)
    /// - Parameters:
    ///  - point: The point at which to set the point of interest. Note that the point provided should conform to the capture device's coordinate system.
    ///  - options: The operations to enable setting the point of interest for. Focusing and rebalancing exposure at the specified point enabled by default.
    public func setPointOfInterest(at point: CGPoint, for options: PointOfInterestOptions = [.exposure, .focus]) {
        guard !(cameraKit.activeInput is ARInput),
            let device = cameraInputDevice
        else {
            return
        }

        do {
            try device.lockForConfiguration()

            if options.contains(.exposure) && device.isExposurePointOfInterestSupported
                && device.isExposureModeSupported(.autoExpose)
            {
                isAdjustingFocusObservation = device.observe(
                    \.isAdjustingExposure,
                    options: .new,
                    changeHandler: restoreContinuousAutoExposure
                )

                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }

            if options.contains(.focus) && device.isFocusPointOfInterestSupported
                && device.isFocusModeSupported(.autoFocus)
            {
                isAdjustingExposureObservation = device.observe(
                    \.isAdjustingFocus,
                    options: .new,
                    changeHandler: restoreContinuousAutoFocus
                )

                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }

            device.unlockForConfiguration()
        } catch {
            print("[CameraKit] Failed to lock device for configuration when trying to set point of interest")
            return
        }
    }

    // MARK: Taking Photos

    /// Takes a photo.
    /// - Parameter completion: completion to be called with the photo or an error.
    public func takePhoto(completion: ((UIImage?, Error?) -> Void)?) {
        let settings = AVCapturePhotoSettings()

        photoCaptureOutput?.capture(
            with: settings,
            outputSize: OutputSizeHelper.normalizedSize(
                for: cameraKit.activeInput.frameSize,
                aspectRatio: UIScreen.main.bounds.width / UIScreen.main.bounds.height)
        ) { image, error in
            completion?(image, error)
        }
    }

    /// Configures the photo output to be ready to capture a new photo.
    fileprivate func configurePhotoCapture() {
        // Add AVCapturePhotoOutput to capture session
        let avPhotoCaptureOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(avPhotoCaptureOutput) {
            captureSession.addOutput(avPhotoCaptureOutput)
        }
        photoCaptureOutput = PhotoCaptureOutput(capturePhotoOutput: avPhotoCaptureOutput)
        if let photoCaptureOutput = photoCaptureOutput {
            cameraKit.add(output: photoCaptureOutput)
        }
    }

    // MARK: LensRepositoryGroupObserver

    open func repository(_ repository: LensRepository, didUpdateLenses lenses: [Lens], forGroupID groupID: String) {
        // prefetch lens content (don't prefetch bundled since content is local already)
        if !groupID.contains(SCCameraKitLensRepositoryBundledGroup) {
            // the object returned here can be used to cancel the ongoing prefetch operation if need be
            _ = cameraKit.lenses.prefetcher.prefetch(lenses: lenses, completion: nil)
            for lens in lenses {
                cameraKit.lenses.prefetcher.addStatusObserver(self, lens: lens)
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let lenses = self.groupIDs.flatMap {
                self.cameraKit.lenses.repository.lenses(groupID: $0)
            }
            self.uiDelegate?.cameraController(self, updatedLenses: lenses)
        }
    }

    open func repository(
        _ repository: LensRepository, didFailToUpdateLensesForGroupID groupID: String, error: Error?
    ) {
    }

    // MARK: LensPrefetcherObserver

    public func prefetcher(_ prefetcher: LensPrefetcher, didUpdate lens: Lens, status: LensFetchStatus) {
        guard let currentLens = currentLens,
            lens.id == currentLens.id,
            lens.groupId == currentLens.groupId
        else {
            return
        }

        DispatchQueue.main.async {
            if status == .loading {
                self.uiDelegate?.cameraControllerRequestedActivityIndicatorShow(self)
            } else {
                self.uiDelegate?.cameraControllerRequestedActivityIndicatorHide(self)
            }
        }
    }

    // MARK: Recording

    /// Begin recording video.
    public func startRecording() {
        configureRecorder()
        recorder?.startRecording()
    }

    /// Cancel recording video.
    public func cancelRecording() {
        finishRecording(completion: nil)
    }

    /// Finish recording the video.
    /// - Parameter completion: completion to be called with a URL to the recorded video or an error.
    public func finishRecording(completion: ((URL?, Error?) -> Void)?) {
        guard let recorder = recorder else { return }
        recorder.finishRecording { url, error in
            DispatchQueue.main.async {
                completion?(url, error)
            }
        }
    }

    // MARK: Lens Application

    /// Apply a specified lens.
    /// - Parameters:
    ///   - lens: selected lens
    ///   - completion: callback on completion with success/failure
    public func applyLens(_ lens: Lens, completion: ((Bool) -> Void)? = nil) {
        lensQueue.async { [weak self] in
            // set current lens right away so we don't apply same lens twice
            self?.currentLens = lens
            guard let self = self, let processor = self.cameraKit.lenses.processor else {
                completion?(false)
                return
            }
            processor.apply(lens: lens, launchData: self.launchData(for: lens)) { [weak self] success in
                if success {
                    print("\(lens.name ?? "Unnamed") (\(lens.id)) Applied")

                    DispatchQueue.main.async { [weak self] in
                        // set camera position based on facing preference
                        self?.changeCameraPosition(with: lens.facingPreference)
                    }

                } else {
                    self?.currentLens = nil
                    print("Lens failed to apply")
                }
                completion?(success)
            }
        }
    }

    /// Clear the currently selected lens, and return to unmodified camera feed.
    ///   - willReapply: if true, cameraKit will not clear out the "currentLens" property, and reapplyCurrentLens will apply the lens that was cleared.
    ///   - completion: callback on completion with success/failure
    public func clearLens(willReapply: Bool = false, completion: ((Bool) -> Void)? = nil) {
        lensQueue.async {
            self.cameraKit.lenses.processor?.clear { completed in
                if !willReapply && completed {
                    self.currentLens = nil
                }

                completion?(completed)
            }
        }
    }

    /// If a lens has already been applied, reapply it.
    public func reapplyCurrentLens() {
        guard let currentLens = currentLens else { return }
        cameraKit.lenses.processor?.apply(lens: currentLens, launchData: nil, completion: nil)
    }

    // MARK: LensHintDelegate

    public func lensProcessor(
        _ lensProcessor: LensProcessor, shouldDisplayHint hint: String, for lens: Lens, autohide: Bool
    ) {
        uiDelegate?.cameraController(self, requestedHintDisplay: hint, for: lens, autohide: autohide)
    }

    public func lensProcessor(_ lensProcessor: LensProcessor, shouldHideAllHintsFor lens: Lens) {
        uiDelegate?.cameraController(self, requestedHintHideFor: lens)
    }

    // MARK: - Private API

    // MARK: Private vars

    /// Temporary state that holds the starting point for the last zoom level
    /// Since pinching is a relative operation, we need to keep whatever it was left at last to compare.
    private var lastZoomLevel: CGFloat = 1

    /// serial queue used to apply/clear lenses
    fileprivate let lensQueue = DispatchQueue(label: "com.snap.camerakit.sample.lensqueue", qos: .userInitiated)

    /// The current camera input device
    fileprivate var cameraInputDevice: AVCaptureDevice? {
        captureSession.inputs
            .compactMap({ ($0 as? AVCaptureDeviceInput)?.device })
            .first(where: { $0.hasMediaType(.video) })
    }

    fileprivate var isAdjustingExposureObservation: NSKeyValueObservation?

    fileprivate var isAdjustingFocusObservation: NSKeyValueObservation?
}

// MARK: Camera Pipeline Configuration

extension CameraController {

    /// Configures the capture session.
    fileprivate func configureCaptureSession() {
        captureSession.beginConfiguration()
        configureDevice(for: .video)
        captureSession.commitConfiguration()
    }

    /// Prompts the user for access, and then calls a completion closure. If the user has already granted access, calls the closure synchronously.
    /// - Parameter completion: the completion closure to call.
    fileprivate func promptForAccessIfNeeded(completion: @escaping () -> Void) {
        guard
            AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
                || AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined
        else {
            completion()
            return
        }

        AVCaptureDevice.requestAccess(for: .video) { _ in
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    /// Configures the device specified.
    /// - Parameter mediaType: the media type, audio or video
    fileprivate func configureDevice(for mediaType: AVMediaType) {
        guard
            let device = mediaType == .video
                ? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
                : AVCaptureDevice.default(for: mediaType),
            let input = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else {
            return
        }
        captureSession.addInput(input)
    }

    /// Directly sets the zoom level, if possible. Certain inputs may ignore calls to this function (eg: ARKit)
    private var zoomLevel: CGFloat {
        get {
            guard !(cameraKit.activeInput is ARInput),
                let device = cameraInputDevice
            else {
                return 1
            }
            return device.videoZoomFactor
        }
        set {
            guard !(cameraKit.activeInput is ARInput),
                let device = cameraInputDevice
            else {
                return
            }
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = max(1.0, min(newValue, device.activeFormat.videoMaxZoomFactor))
                device.unlockForConfiguration()
            } catch {
                print("[CameraKit] Failed to lock device for configuration when trying to adjust zoom level")
                return
            }

        }
    }

}

// MARK: Recording

extension CameraController {

    /// Configures the recorder to be ready to record a new video.
    fileprivate func configureRecorder() {
        if let old = recorder {
            cameraKit.remove(output: old.output)
        }
        recorder = try? Recorder(
            url: URL(fileURLWithPath: "\(NSTemporaryDirectory())\(UUID().uuidString).mp4"),
            orientation: cameraKit.activeInput.frameOrientation,
            size: OutputSizeHelper.normalizedSize(
                for: cameraKit.activeInput.frameSize,
                aspectRatio: UIScreen.main.bounds.width / UIScreen.main.bounds.height,
                orientation: cameraKit.activeInput.frameOrientation)
        )
        if let recorder = recorder {
            cameraKit.add(output: recorder.output)
        }
    }

}

// MARK: Lens Application

extension CameraController {

    /// Generates the launch data for the lens. By default, this is just the vendor data attached to the lens.
    /// - Parameter lens: the lens to generate launch data for
    /// - Returns: launch data.
    private func launchData(for lens: Lens) -> LensLaunchData {
        guard !lens.vendorData.isEmpty else {
            return EmptyLensLaunchData()
        }

        let launchDataBuilder = LensLaunchDataBuilder()
        for (key, val) in lens.vendorData {
            launchDataBuilder.add(string: val, key: key)
        }
        return launchDataBuilder.launchData ?? EmptyLensLaunchData()
    }

}

// MARK: Notifications

extension CameraController {

    /// Observes notifications relevant to the camera controller.
    fileprivate func configureNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.appWillEnterForegroundNotification(_:)),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    /// Notifies the camera controller that the app is about to background. The app must stop processing until re-foregrounded.
    /// - Parameter notification: the NSNotification.
    @objc private func appWillEnterForegroundNotification(_ notification: Notification) {
        // SDK pauses/disables lens in background, so re-apply the lens when entering foreground
        guard let currentLens = currentLens else { return }
        applyLens(currentLens)
    }

}

// MARK: Key-Value Observing

extension CameraController {

    /// Restores continuous autoexposure after the camera finishes a user-initiated tap to focus
    private func restoreContinuousAutoExposure(_ device: AVCaptureDevice, _ change: NSKeyValueObservedChange<Bool>) {
        guard let isAdjustingExposure = change.newValue,
            !isAdjustingExposure
        else {
            return
        }

        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            print("[CameraKit] Failed to lock device for configuration when trying to restore continuous autoexposure")
            return
        }
    }

    /// Restores continuous autofocus after the camera finishes a user-initiated tap to focus
    private func restoreContinuousAutoFocus(_ device: AVCaptureDevice, _ change: NSKeyValueObservedChange<Bool>) {
        guard let isAdjustingFocus = change.newValue,
            !isAdjustingFocus
        else {
            return
        }

        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            device.unlockForConfiguration()
        } catch {
            print("[CameraKit] Failed to lock device for configuration when trying to restore continuous autofocus")
            return
        }
    }

}

// MARK: Lens facing preference

extension CameraController {

    /// Set camera position based on lens facing preference.
    private func changeCameraPosition(with lensFacing: LensFacingPreference) {
        var position: AVCaptureDevice.Position?
        switch lensFacing {
        case .front: position = .front
        case .back: position = .back
        default: break
        }

        if let position = position,
            position != cameraPosition
        {
            uiDelegate?.cameraControllerRequestedCameraFlip(self)
        }
    }
}
