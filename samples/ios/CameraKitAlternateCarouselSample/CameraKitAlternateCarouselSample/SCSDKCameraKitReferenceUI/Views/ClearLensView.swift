//  Copyright Snap Inc. All rights reserved.
//  CameraKitSandbox

import UIKit

/// Current lens information bar as well as close button to clear current lens
public class ClearLensView: UIView {
    private enum Constants {
        static let closeCircle = "ck_close_circle"
    }

    /// Close button to clear current lens
    public let closeButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = ClearLensElements.closeButton.id
        button.setImage(
            UIImage(named: Constants.closeCircle, in: BundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    /// Current lens name
    public let lensLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.sc_demiBoldFont(size: 14)
        label.textAlignment = .center

        return label
    }()

    /// Lens Icon
    public let imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        layer.cornerRadius = 12
        addSubview(lensLabel)
        addSubview(closeButton)
        addSubview(imageView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),

            lensLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            lensLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),

            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.leadingAnchor.constraint(equalTo: lensLabel.trailingAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 8),
        ])
    }
}
