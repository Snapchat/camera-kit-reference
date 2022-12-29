//  Copyright Snap Inc. All rights reserved.
//  CameraKit

import UIKit

/// A set of functions implemented by the delegate to be notified when the lens picker responds to user interactions.
public protocol LensPickerViewDelegate: AnyObject {

    /// Notifies the delegate that a specific index was selected from the lens picker.
    /// - Parameters:
    ///   - view: The lens picker view which contains the item that was just selected.
    ///   - item: The lens picker item which was just selected.
    ///   - index: The index at which the lens picker item was selected.
    func lensPickerView(_ view: LensPickerView, didSelect item: LensPickerItem, at index: Int)
}

/// A set of functions that an object adopts to manage data and provide items for a lens picker view.
public protocol LensPickerViewDataSource: AnyObject {

    /// Returns a list of items to show in the lens picker view.
    /// - Parameters:
    ///   - view: The lens picker view which will show the list of items returned.
    /// - Returns: A list of items to show in the lens picker view.
    func itemsForLensPickerView(_ view: LensPickerView) -> [LensPickerItem]
}

/// A view that manages an ordered collection of data items (eg. lenses) and displays them in a swipeable row with one item always selected.
public class LensPickerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    /// The delegate for the lens picker view which will be notified of the lens picker view actions.
    public weak var delegate: LensPickerViewDelegate?

    /// The object that manages data and provides items for the lens picker view.
    public weak var dataSource: LensPickerViewDataSource? {
        didSet {
            reloadData()
        }
    }

    /// Reloads all of the data in the lens picker view to display the latest lens picker items.
    public func reloadData() {
        items = dataSource?.itemsForLensPickerView(self) ?? []
        collectionView.reloadData()
    }

    /// Current selected item or nil if none are selected.
    public private(set) var selectedItem: LensPickerItem = EmptyItem()

    /// Current list of items in the lens picker.
    private var items = [LensPickerItem]()

    /// Image loader instance used to load each item icon.
    let imageLoader = DefaultLensPickerImageLoader()

    // MARK: Views

    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8.0
        layout.minimumLineSpacing = 8.0
        layout.scrollDirection = .vertical
        return layout
    }()

    // Collection view which is the "lens picker" itself.
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        view.accessibilityIdentifier = LensPickerElements.collectionView.id
        view.contentInsetAdjustmentBehavior = .never
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.decelerationRate = .fast
        view.register(LensPickerCollectionViewCell.self, forCellWithReuseIdentifier: Constants.cellIdentifier)
        view.showsHorizontalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.bounces = false

        let collectionViewXInset = (UIScreen.main.bounds.width - Constants.cellWidth*3 - 16)/2
        view.contentInset = UIEdgeInsets(top: 28, left: collectionViewXInset, bottom: 0, right: collectionViewXInset)

        return view
    }()

    private lazy var topBlurHeader: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.backgroundColor = UIColor(hex: 0x343434, alpha: 0.7)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .white
        setupCollectionView()
        setupTopBlurHeaderView()
    }

    private func setupCollectionView() {
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupTopBlurHeaderView() {
        addSubview(topBlurHeader)
        NSLayoutConstraint.activate([
            topBlurHeader.topAnchor.constraint(equalTo: topAnchor),
            topBlurHeader.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBlurHeader.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBlurHeader.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    /// To be called the first time a filter is applied.
    /// - Parameter indexPath: The index path of the color cell to initially select.
    public func performInitialSelection(indexPath: IndexPath = IndexPath(row: 0, section: 0)) {
        collectionView(collectionView, didSelectItemAt: indexPath)
    }

    // MARK: Items

    /// Select lens picker item
    /// Returns true if item exists in lens picker and is selected or false if failed to select item
    /// - Parameter selected: lens picker item to select
    @discardableResult
    public func selectItem(_ selected: LensPickerItem) -> Bool {
        /// If there is a previous item selected, unselect it
        if let index = items.firstIndex(where: {$0.id == selectedItem.id }) {
            collectionView.deselectItem(at: IndexPath(item: index, section: 0), animated: true)
        }

        if items.firstIndex(where: { $0.id == selected.id }) != nil {
            selectedItem = selected
            return true
        } else {
            selectedItem = EmptyItem()
            return false
        }
    }

    // MARK: Collection View

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellIdentifier, for: indexPath)
            as! LensPickerCollectionViewCell

        let item = items[indexPath.item]
        cell.imageView.image =
            item.image
            ?? UIImage(named: Constants.imagePlaceholder, in: BundleHelper.resourcesBundle, compatibleWith: nil)
        if item.image == nil && item.imageUrl != nil {
            cell.activityIndicatorView.startAnimating()
        } else {
            cell.activityIndicatorView.stopAnimating()
        }

        cell.accessibilityIdentifier = LensPickerElements.lensCell.id
        cell.accessibilityLabel = item.lensId

        cell.lensLabel.text = item.lensName ?? item.lensId

        // handle initial state edge case issues
        // normal lens: don't transform initial state
        // empty lens: set alpha to 0
        if selectedItem.id == item.id {
            if item is EmptyItem {
                cell.contentView.alpha = 0.0
            } else {
                cell.transform = .identity
            }
        }

        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath
    ) {
        guard items[indexPath.item].image == nil else {
            return
        }

        fetchImage(indexPath: indexPath)
    }

    public func collectionView(
        _ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath
    ) {
        guard indexPath.item < items.count,
            let url = items[indexPath.item].imageUrl
        else { return }
        imageLoader.cancelImageLoad(from: url)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        selectItemHelper(at: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constants.cellWidth, height: Constants.cellHeight)
    }

    // MARK: Helper

    /// Helper method to fetch image for cell at index path and update cell on completion
    /// - Parameter indexPath: index path of cell
    private func fetchImage(indexPath: IndexPath) {
        guard let url = items[indexPath.item].imageUrl else { return }
        let id = items[indexPath.item].id

        imageLoader.loadImage(url: url) { [weak self] (image, error) in
            guard let strongSelf = self,
                indexPath.item < strongSelf.items.count,
                strongSelf.items[indexPath.item].id == id
            else {
                // ensure cell index path still exists after image finishes downloading
                // since lens picker data can be reloaded in that time
                return
            }
            strongSelf.items[indexPath.item].image = image

            guard let cell = strongSelf.collectionView.cellForItem(at: indexPath) as? LensPickerCollectionViewCell else {
                return
            }
            cell.imageView.image = image
            cell.activityIndicatorView.stopAnimating()
        }
    }

    /// Select item at index and notify delegate
    /// - Parameter index: index of item
    private func selectItemHelper(at index: Int) {
        guard index >= 0,
            index < items.count
        else {
            return
        }

        selectedItem = items[index]
        delegate?.lensPickerView(self, didSelect: items[index], at: index)
    }

}

// MARK: Constants

private extension LensPickerView {

    enum Constants {
        static let cellIdentifier = "SCCameraKitLensPickerCollectionViewCell"
        static let imagePlaceholder = "ck_lens_placeholder"
        static let cellWidth = 109.0
        static let cellHeight = 108.0
    }

}
