//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import UIKit

protocol LensPickerViewControllerDelegate: AnyObject {
    func didPresentLensPickerViewController()
    func didDismissLensPickerViewController()
}

/// This is the lens picker view that appears as a bottom sheet.
public class LensPickerViewController: UIViewController {

    /// The backing view.
    public var lensPickerView: LensPickerView

    weak var delegate: LensPickerViewControllerDelegate?

    init(lensPickerView: LensPickerView) {
        self.lensPickerView = lensPickerView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view = lensPickerView
        view.backgroundColor = UIColor(hex: 0x1E1E1E, alpha: 1.0)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        lensPickerView.reloadData()
        self.delegate?.didPresentLensPickerViewController()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        self.delegate?.didDismissLensPickerViewController()
        lensPickerView.reloadData()
    }

}
