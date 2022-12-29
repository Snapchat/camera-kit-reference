//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import Photos
import UIKit

/// Preview view controller for showing captured photos and images
public class ImagePreviewViewController: PreviewViewController {

    // MARK: Properties

    /// UIImage to display
    public let image: UIImage

    fileprivate lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.accessibilityIdentifier = PreviewElements.imageView.id
        view.contentMode = .scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    // MARK: Init

    /// Designated init to pass in required deps
    /// - Parameter image: UIImage to display
    public init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: Setup

    private func setup() {
        view.insertSubview(imageView, at: 0)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: Action Overrides

    override func sharePreview() {
        let viewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(viewController, animated: true, completion: nil)
    }

    override func savePreview() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: self.image)
        }) { (saved, error) in
            var title: String
            var message: String
            if saved {
                title = "Save Success"
                message = "Successfully saved photo to library"
            } else {
                title = "Save Failure"
                message = "Failed to save photo to library"
                print("failed to save video with error: \(error?.localizedDescription ?? "no error")")
            }

            DispatchQueue.main.async {
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
