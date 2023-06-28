import Foundation
import SCSDKCameraKit
import SCSDKCameraKitReferenceUI
import SwiftUI
import Combine

// WARNING: Push to Device support cannot be shipped to the App Store.
// Push to Device must be compiled out before submission.
 #if CAMERAKIT_PUSHTODEVICE
     import SCSDKCameraKitBaseExtension
     import SCSDKCameraKitLoginKitAuth
     import SCSDKCameraKitPushToDeviceExtension
 #endif

/// A customized version of the Camera View Controller, adding app-specific features like Push to Device and a debugging sheet.
class CustomizedCameraViewController: CameraViewController {

#if CAMERAKIT_PUSHTODEVICE
     /// Manages push to device communication
     private lazy var pushToDevice: PushToDevice = {
         let loginKitTokenProvider = LoginKitAccessTokenProvider()
         return PushToDevice(
             cameraKitSession: cameraController.cameraKit,
             tokenProvider: loginKitTokenProvider
         )
     }()

     /// Button to activate the push to device flow
     fileprivate let devicePairingButton: UIButton = {
         let button = UIButton(type: .custom)
         button.setImage(
             UIImage(named: "PushToDevice"), for: .normal
         )
         button.tintColor = .white
         button.translatesAutoresizingMaskIntoConstraints = false
         return button
     }()
 #endif
    
    public let debugSheetButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black.withAlphaComponent(0.25)
        button.layer.cornerRadius = 15
        button.setImage(UIImage(named: "DebugActive"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var debugStore: (any DebugStoreProtocol)? = nil
    private var debugCancellables: Set<AnyHashable> = []
    
    init(cameraController: CameraController, debugStore: (any DebugStoreProtocol)?) {
        self.debugStore = debugStore
        super.init(cameraController: cameraController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDebugSheetButton()
#if CAMERAKIT_PUSHTODEVICE
        setUpPushToDeviceButton()
#endif
    }
    
    /// Configures the debug sheet button.
    func setUpDebugSheetButton() {
        cameraView.addSubview(debugSheetButton)
        NSLayoutConstraint.activate([
            debugSheetButton.topAnchor.constraint(equalTo: cameraView.topAnchor, constant: 50),
            debugSheetButton.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor, constant: 20),
        ])
        debugSheetButton.addTarget(self, action: #selector(lensDebugSheetAction), for: .touchUpInside)
    }
    
    /// The user has tapped the debug sheet button.
    /// - Parameter sender: the button that was tapped
    @objc func lensDebugSheetAction(_ sender: UIButton) {
        if #available(iOS 13.0.0, *) {
            guard let debugStore = debugStore as? DebugStore else { return }
            let vc = UIHostingController(rootView: DebugView(store: debugStore))
            let cancellable = debugStore.$groupIDs.sink { [weak self] groupIDs in
                guard let self = self else { return }
                guard self.cameraController.groupIDs != groupIDs else { return }
                self.cameraController.groupIDs = groupIDs
                self.cameraView.carouselView.selectItem(EmptyItem())
                self.cameraController.clearLens()
                self.cameraView.carouselView.reloadData()
            }
            _ = debugCancellables.insert(cancellable)
            let nav = UINavigationController(rootViewController: vc)
            if #available(iOS 15.0, *) {
                nav.sheetPresentationController?.detents = [.medium()]
            }
            present(nav, animated: true, completion: nil)
        }
    }
}

#if CAMERAKIT_PUSHTODEVICE

// MARK: Push To Device UI

fileprivate extension CustomizedCameraViewController {
    
    /// Configures the push to device button in the toolbar.
    func setUpPushToDeviceButton() {
        if let extensibleSession = cameraController.cameraKit as? CameraKitExtensible {
            extensibleSession.register(pushToDevice)
            pushToDevice.delegate = self
            cameraController.groupIDs.insert(SCCameraKitPushToDeviceGroupID, at: 0)
        }
        cameraView.cameraActionsView.buttonStackView.addArrangedSubview(devicePairingButton)
        NSLayoutConstraint.activate([
            devicePairingButton.widthAnchor.constraint(equalToConstant: 40),
            devicePairingButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        devicePairingButton.addTarget(self, action: #selector(pairingButtonTapped(sender:)), for: .touchUpInside)
    }
    
    /// The user has tapped the pairing initiation button.
    /// - Parameter sender: the button that was tapped
    @objc
    func pairingButtonTapped(sender: Any) {
        cameraView.showMessage(
            text: "Pairing Initiated. Login and scan the Snapcode on LensStudio",
            numberOfLines: 3
        )
        pushToDevice.initiatePairing()
        // Flip to rear camera for snapcode scanning if we're on front
        if cameraController.cameraPosition == .front {
            cameraController.flipCamera()
        }
    }
}

// MARK: Push to Device Delegate

extension CameraViewController: PushToDeviceDelegate {
    
    public func pushToDeviceDidAcquireAuthToken(_ pushToDevice: PushToDeviceProtocol) {
        showAlert("Logged in. Scan a Snapcode to pair with lens studio", numberOfLines: 0, duration: 5)
    }
    
    public func pushToDevice(_ pushToDevice: PushToDeviceProtocol, failedToAcquireAuthToken error: Error) {
        showAlert("Failed to acquire authentication token: \(error.localizedDescription)")
    }
    
    public func pushToDeviceDidScanSnapcode(_ pushToDevice: PushToDeviceProtocol) {
        showAlert("A snapcode was scanned")
    }
    
    public func pushToDevice(_ pushToDevice: PushToDeviceProtocol, failedToScanSnapcodeWithError error: Error) {
        showAlert("Failed to scan snapcode: \(error.localizedDescription)")
    }
    
    public func pushToDeviceComplete(_ pushToDevice: PushToDeviceProtocol) {
        showAlert("Pairing succeeded 🎉")
    }
    
    public func pushToDevice(_ pushToDevice: PushToDeviceProtocol, didReceiveLensPushError error: Error) {
        showAlert("An error happened \(error.localizedDescription)")
    }
    
    public func push(toDevice pushToDevice: PushToDeviceProtocol, receivedLens lens: Lens) {
        showAlert("A lens was pushed")
        DispatchQueue.main.async {
            self.cameraView.carouselView.selectItem(CarouselItem(lensId: lens.id, groupId: lens.groupId))
            self.applyLens(lens)
        }
    }
    
    private func showAlert(_ message: String, numberOfLines: Int = 1, duration: TimeInterval = 1.5) {
        DispatchQueue.main.async {
            self.cameraView.showMessage(text: message, numberOfLines: numberOfLines, duration: duration)
        }
    }
}

#endif


/// A customzied version of the Camera Controller, demonstrating how to customize the data providers.
class CustomizedCameraController: CameraController {
    
    override func configureDataProvider() -> DataProviderComponent {
        DataProviderComponent(
            deviceMotion: nil, userData: UserDataProvider(), lensHint: nil, location: nil,
            mediaPicker: lensMediaProvider, remoteApiServiceProviders: [CatFactRemoteApiServiceProvider()])
    }
    
}
