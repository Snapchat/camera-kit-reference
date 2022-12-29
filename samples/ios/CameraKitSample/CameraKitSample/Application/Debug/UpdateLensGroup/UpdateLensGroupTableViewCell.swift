//  UpdateLensGroupTableViewCell.swift
//  CameraKitSample

import UIKit
import SCSDKCameraKitReferenceUI

protocol UpdateLensGroupDelegate: AnyObject {

    func tableViewCurrentCellEditing(cell: UpdateLensGroupCell?)

    /// Notifies the delegate that the content for a row in the tableview has been updated
    /// - Parameter cell: The cell contained in the updated row
    func updateRow(cell: UpdateLensGroupCell)
}

class UpdateLensGroupCell: UITableViewCell, UITextFieldDelegate {

    /// Textfield that allows users to view/modify group ID
    public lazy var textField: UITextField = {
        let field = UITextField()
        field.placeholder = NSLocalizedString("camera_kit_group_id_textfield_placeholder", comment: "")
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        field.delegate = self
        return field
    }()

    /// Update lens group delegate to update lens groups
    weak var delegate: UpdateLensGroupDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        contentView.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        ])

    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.tableViewCurrentCellEditing(cell: self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.updateRow(cell: self)
        endEditing(true)
        return false
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        delegate?.updateRow(cell: self)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.updateRow(cell: self)
        endEditing(true)
    }
}

