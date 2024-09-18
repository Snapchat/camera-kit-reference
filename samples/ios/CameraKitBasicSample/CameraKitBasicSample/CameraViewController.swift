import UIKit
import AVFoundation
import SCSDKCameraKit

class CameraViewController: UIViewController {
    /// A capture session we'll use for camera input.
    public let captureSession = AVCaptureSession()

    /// The CameraKit session
    public var cameraKit: CameraKitProtocol!
    
    private enum Constants {
        static let apiToken = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
        static let lensId = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
        static let groupId = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
    }
    
    /// A UIView for previewing Camera Kit lenses. Add this as an output to CameraKit instance.
    public let previewView = PreviewView()
    
    /// Serial queue used to apply/clear lenses
    private let lensQueue = DispatchQueue(label: "com.snap.camerakit.sample.lensqueue", qos: .userInitiated)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = previewView
        setupCameraKit()
    }
    
    /// Set the properties for Camera Kit session, add inputs and an output to preview Lenses
    private func setupCameraKit() {
        // (1)  Configure properties for a CameraKit Session. The maximum size of the lens content cache is 150 * 1024 * 1024, or 150MB
        self.cameraKit = Session(sessionConfig: SessionConfig(apiToken: Constants.apiToken),
                                 lensesConfig: LensesConfig(cacheConfig: CacheConfig(lensContentMaxSize: 150 * 1024 * 1024)),
                                 errorHandler: nil)

        // (2) Add inputs to the Camera Kit Session
        let input = AVSessionInput(session: captureSession)
        let arInput = ARSessionInput()
        
        // (3) Add output to see the AR Experience coming out of Camera Kit
        previewView.automaticallyConfiguresTouchHandler = true
        cameraKit.add(output: previewView)
        
        // (4) Start the Camera Kit session
        cameraKit.start(input: input, arInput: arInput)
        
        // (5) Observe a particular lens
        cameraKit.lenses.repository.addObserver(self, specificLensID: Constants.lensId, inGroupID: Constants.groupId)
        
        // (6) start the input
        DispatchQueue.global(qos: .background).async {
            input.startRunning()
        }
    }
    
    /// Apply a lens.
    /// - Parameters:
    ///   - lens: selected lens
    public func apply(lens: Lens) {
        // (7) Convenience method for applying an observed Lens
        lensQueue.async { [weak self] in
            guard let self = self else { return }
            self.cameraKit.lenses.processor?.apply(lens: lens, launchData: nil) { success in
                if success {
                    print("\(lens.name ?? "Unnamed") (\(lens.id)) Applied")
                } else {
                    print("Lens failed to apply")
                }
            }
        }
    }
}

extension CameraViewController: LensRepositorySpecificObserver {
    // (8) LensRepositorySpecificObserver method to observe and receive changes to specific lenses
    func repository(_ repository: LensRepository, didUpdate lens: Lens, forGroupID groupID: String) {
        apply(lens: lens)
    }
    
    func repository(_ repository: LensRepository, didFailToUpdateLensID lensID: String, forGroupID groupID: String, error: Error?) {
        if let error {
            print("Did fail to update lens: \(error.localizedDescription)")
        }
    }
}
