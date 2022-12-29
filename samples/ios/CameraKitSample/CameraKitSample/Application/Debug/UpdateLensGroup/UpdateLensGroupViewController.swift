//  UpdateLensGroupViewController.swift
//  CameraKitSample

import UIKit
import SCSDKCameraKitReferenceUI

class UpdateLensGroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    enum Constants {
        static let lensGroupIDsKey = "com.snap.camerakit.sample.lensGroupIDsKey"
    }

    /// Tableview displays all lens group IDs
    public lazy var tableView: UITableView = {
        let view = UITableView()
        view.contentInsetAdjustmentBehavior = .never
        view.delegate = self
        view.dataSource = self
        view.decelerationRate = .fast
        view.register(UpdateLensGroupCell.self, forCellReuseIdentifier: String(describing: UpdateLensGroupCell.self))
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.rowHeight = 50
        return view
    }()

    /// Holds all group IDs currently used
    var allGroupIDs: [String]
    let cameraController: CameraController
    let carouselView: CarouselView

    /// Stores current cell being edited, if any, so that if user exits screen before finishing editing, the edits are saved
    weak var currentCellEditing: UpdateLensGroupCell?

    init(cameraController: CameraController, carouselView: CarouselView) {
        self.cameraController = cameraController
        self.carouselView = carouselView

        if let previousGroupIDs = UserDefaults.standard.object(forKey: Constants.lensGroupIDsKey) as? [String] {
            self.allGroupIDs = previousGroupIDs
        } else {
            /// Since there will always be an empty row at the bottom of the tableview, we check if we need to manually add that empty row by seeing if the last item in the groupIDs is an empty string. If not, to manually add it, we append an empty string at the end of allGroupIDs
            self.allGroupIDs = cameraController.groupIDs + ((cameraController.groupIDs.last?.isEmpty ?? false) ? [] : [""])
        }

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
                navigationController?.sheetPresentationController?.detents = [.large()]
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let cell = currentCellEditing {
            updateRow(cell: cell)
        }
        cameraController.groupIDs = allGroupIDs
        UserDefaults.standard.set(allGroupIDs, forKey: Constants.lensGroupIDsKey)
        carouselView.selectItem(EmptyItem())
        cameraController.clearLens()
        carouselView.reloadData()
        super.viewWillDisappear(animated)
    }

    func setUp() {
        navigationItem.title = NSLocalizedString("camera_kit_debug_nav_title", comment: "")
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemBackground
        } else {
            view.backgroundColor = .lightGray
        }
        tableView.backgroundColor = view.backgroundColor
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UpdateLensGroupCell.self), for: indexPath) as! UpdateLensGroupCell
        cell.textField.text = allGroupIDs[indexPath.item]
        cell.delegate = self
        cell.backgroundColor = tableView.backgroundColor
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allGroupIDs.count
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard indexPath.item < allGroupIDs.count-1 else { return .none }
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete && indexPath.item < allGroupIDs.count-1 else { return }
        allGroupIDs.remove(at: indexPath.row)
        tableView.deleteRows(at:[indexPath], with: .automatic)
    }

}

// MARK: Update Lens Group Delegate

extension UpdateLensGroupViewController: UpdateLensGroupDelegate {

    /// Updates currentCellEditing to current cell being edited, so that if user exits screen before they finish editing, the edits are saved
    func tableViewCurrentCellEditing(cell: UpdateLensGroupCell?) {
        currentCellEditing = cell
    }

    func updateRow(cell: UpdateLensGroupCell) {
        guard let index = tableView.indexPath(for: cell)?.item else { return }
        allGroupIDs[index] = cell.textField.text ?? ""
        if index == allGroupIDs.count-1 && !allGroupIDs[index].isEmpty {
            addRow()
        }
        tableViewCurrentCellEditing(cell: nil)
    }

    func addRow() {
        allGroupIDs.append("")
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: allGroupIDs.count-1, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
}
