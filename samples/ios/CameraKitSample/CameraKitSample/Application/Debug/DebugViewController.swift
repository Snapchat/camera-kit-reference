//  DebugViewController.swift
//  CameraKitSample

import UIKit
import SCSDKCameraKitReferenceUI

class DebugViewController: UIViewController {

    /// Button to navigate to update lens group view controller
    var updateLensGroupButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("camera_kit_update_lens_group_button", comment: ""), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        if #available(iOS 13.0, *) {
            button.setTitleColor(.link, for: .normal)
            button.backgroundColor = .tertiarySystemBackground
        } else {
            button.setTitleColor(.blue, for: .normal)
            button.backgroundColor = .darkGray
        }
        return button
    }()

    /// View controller for updating lens groups
    lazy var updateLensGroupViewController = UpdateLensGroupViewController(cameraController: cameraController, carouselView: carouselView)

    let cameraController: CameraController
    let carouselView: CarouselView

    init(cameraController: CameraController, carouselView: CarouselView) {
        self.cameraController = cameraController
        self.carouselView = carouselView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 15.0, *) {
            navigationController?.sheetPresentationController?.animateChanges {
                navigationController?.sheetPresentationController?.detents = [.medium()]
            }
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("camera_kit_done_button", comment: ""), style: .done, target: self, action: #selector(dismissButton))
    }

    private func setUp() {
        navigationItem.title = NSLocalizedString("camera_kit_debug_nav_title", comment: "")
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemBackground
        } else {
            view.backgroundColor = .lightGray
        }
        navigationController?.view.backgroundColor = view.backgroundColor
        view.addSubview(updateLensGroupButton)

        NSLayoutConstraint.activate([
            updateLensGroupButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            updateLensGroupButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            updateLensGroupButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            updateLensGroupButton.heightAnchor.constraint(equalToConstant: 60),
        ])

        updateLensGroupButton.addTarget(self, action: #selector(updateLensGroupButtonTapped), for: .touchUpInside)
    }

    @objc func updateLensGroupButtonTapped(_ sender: UIButton) {
        navigationController?.pushViewController(updateLensGroupViewController, animated: true)
    }
    
    @objc func dismissButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
