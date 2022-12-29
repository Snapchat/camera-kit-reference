//  Copyright Snap Inc. All rights reserved.
//  SCSDKCameraKitReferenceUI

import SCSDKCameraKit
import UIKit

/// Reference implementation of a text input view for lenses that take text input.
@objc public class KeyboardAccessoryViewProvider: NSObject, TextInputKeyboardAccessoryProvider {

    public let textView: UITextView = PlaceholderTextView()
    public let accessoryView = UIView()
    public var placeholderText: String? {
        get {
            (textView as? PlaceholderTextView)?.placeholderText
        }
        set {
            (textView as? PlaceholderTextView)?.placeholderText = newValue
        }
    }
    public let maximumHeight: CGFloat = Constants.maximumTextViewHeight + (Constants.borderInset * 2)

    private let preferredHeightConstraint: NSLayoutConstraint

    override init() {
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        accessoryView.backgroundColor = UIColor.ck_dynamic(light: .white, dark: UIColor(white: 18.0 / 255.0, alpha: 1))
        textView.translatesAutoresizingMaskIntoConstraints = false
        accessoryView.addSubview(textView)
        accessoryView.addConstraints([
            accessoryView.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: -Constants.borderInset),
            accessoryView.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: Constants.borderInset),
            accessoryView.topAnchor.constraint(equalTo: textView.topAnchor, constant: -Constants.borderInset),
            accessoryView.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: Constants.borderInset),
        ])
        textView.backgroundColor = UIColor.ck_dynamic(
            light: UIColor(white: 242.0 / 255.0, alpha: 1), dark: UIColor(white: 42.0 / 255.0, alpha: 1))

        textView.layer.cornerRadius = Constants.minimumTextViewHeight / 2
        textView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        textView.showsVerticalScrollIndicator = false
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.font = .systemFont(ofSize: 18)
        textView.isScrollEnabled = false
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        accessoryView.addSubview(borderView)
        accessoryView.addConstraints([
            borderView.heightAnchor.constraint(equalToConstant: 1),
            borderView.leadingAnchor.constraint(equalTo: accessoryView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor),
            borderView.topAnchor.constraint(equalTo: accessoryView.topAnchor),
        ])
        borderView.backgroundColor = UIColor.ck_dynamic(
            light: UIColor(white: 238.0 / 255.0, alpha: 1), dark: UIColor(white: 41.0 / 255.0, alpha: 1))

        preferredHeightConstraint = textView.heightAnchor.constraint(equalToConstant: Constants.minimumTextViewHeight)
        preferredHeightConstraint.identifier = "Preferred"
        textView.addConstraints([
            preferredHeightConstraint
        ])

        super.init()

        // Using a notification here to not interfere with external delegates.
        NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification, object: textView, queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let height = self.textView.sizeThatFits(
                CGSize(
                    width: self.textView.frame.width
                        - (self.textView.textContainerInset.left + self.textView.textContainerInset.right),
                    height: .infinity)
            ).height
            let resolved = max(min(height, Constants.maximumTextViewHeight), Constants.minimumTextViewHeight)
            self.preferredHeightConstraint.constant = resolved
            self.textView.isScrollEnabled = height > Constants.maximumTextViewHeight
            self.accessoryView.layoutIfNeeded()
        }
    }

}

/// Simple text view implementation that supports placeholder text.
class PlaceholderTextView: UITextView {

    var placeholderText: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.placeholderLabel.text = self?.placeholderText
            }
        }
    }

    let placeholderLabel = UILabel()

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        addSubview(placeholderLabel)
        placeholderLabel.textColor = UIColor.ck_dynamic(
            light: UIColor(red: 154.0 / 255.0, green: 159.0 / 255.0, blue: 167.0 / 255.0, alpha: 1),
            dark: UIColor(white: 97.0 / 255.0, alpha: 1))
        updatePlaceholderFrame()
        NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification, object: self, queue: .main
        ) { [weak self] _ in
            self?.placeholderLabel.isHidden = !(self?.text.isEmpty ?? false)
        }
    }

    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePlaceholderFrame()
    }

    func updatePlaceholderFrame() {
        placeholderLabel.frame = bounds.insetBy(dx: contentInset.left, dy: contentInset.top)
    }

}

extension KeyboardAccessoryViewProvider {

    enum Constants {
        static let minimumTextViewHeight: Double = 40
        static let maximumTextViewHeight: Double = 60
        static let borderInset: Double = 9
    }

}

extension UIColor {

    /// Convenience implementation of a pre-iOS 13 dynamic color support.
    /// - Parameters:
    ///   - light: Color to use in light mode, or pre-13.
    ///   - dark: Color to use in dark mode.
    /// - Returns: A dynamic color.
    static func ck_dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .light:
                    return light
                case .dark:
                    return dark
                default:
                    return light
                }
            }
        } else {
            return light
        }
    }

}
