//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import UIKit

/// Lens picker collection view cell which represents a single lens item
public class LensPickerCollectionViewCell: UICollectionViewCell {

    /// Cell background
    public let cellBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: 0x343434, alpha: 1.0)
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.white.cgColor

        return view
    }()

    /// Lens Name
    public let lensLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.sc_demiBoldFont(size: 12)
        label.textAlignment = .center

        return label
    }()

    /// Lens Icon
    public let imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: 0x343434, alpha: 1.0)
        return view
    }()

    /// Activity indicator view that should activate when lens content is loading
    public let activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            view.style = .medium
            view.color = .white
        } else {
            view.style = .white
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Add border if lens is selected
    public override var isSelected: Bool {
        didSet {
            if self.isSelected {
                cellBackgroundView.layer.borderWidth = 2
            } else {
                cellBackgroundView.layer.borderWidth = 0
            }
        }
    }

    public init() {
        super.init(frame: .zero)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isAccessibilityElement = true
        contentView.addSubview(cellBackgroundView)
        contentView.addSubview(imageView)
        contentView.addSubview(lensLabel)
        contentView.addSubview(activityIndicatorView)
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cellBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cellBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cellBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cellBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),

            lensLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            lensLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            lensLabel.widthAnchor.constraint(equalToConstant: 85),

            activityIndicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
}
