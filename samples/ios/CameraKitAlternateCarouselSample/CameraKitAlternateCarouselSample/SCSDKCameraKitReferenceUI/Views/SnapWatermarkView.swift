//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import UIKit

/// Bottom bar on Camera that contains Snap ghost button for actions
/// as well as close button to clear current lens
public class SnapWatermarkView: UIView {
    private enum Constants {
        static let poweredBy = "Powered by"
        static let snapGhostOutline = "ck_snap_ghost_outline"
    }

    public let poweredByLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.sc_regularFont(size: 18)
        label.textAlignment = .center
        label.text = Constants.poweredBy
        label.sizeToFit()

        return label
    }()

    public let snapIconImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: Constants.snapGhostOutline, in: BundleHelper.resourcesBundle, compatibleWith: nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
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
        addSubview(poweredByLabel)
        addSubview(snapIconImage)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 124),

            poweredByLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            poweredByLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            snapIconImage.leadingAnchor.constraint(equalTo: poweredByLabel.trailingAnchor, constant: 4),
            snapIconImage.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
