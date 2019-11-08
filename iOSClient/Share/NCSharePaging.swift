//
//  NCSharePaging.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 25/07/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


import Foundation
import Parchment
import NCCommunication

class NCSharePaging: UIViewController {
    
    private let pagingViewController = NCShareHeaderViewController()
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @objc var metadata: tableMetadata?
    @objc var indexPage: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagingViewController.metadata = metadata
        
        // Navigation Controller
        var image = CCGraphics.changeThemingColorImage(UIImage(named: "exitCircle")!, width: 60, height: 60, color: NCBrandColor.sharedInstance.brandText)
        image = image?.withRenderingMode(.alwaysOriginal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style:.plain, target: self, action: #selector(exitTapped))
        
        // Pagination
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        
        // Customization
        pagingViewController.indicatorOptions = .visible(
            height: 1,
            zIndex: Int.max,
            spacing: .zero,
            insets: UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        )
        
        // Contrain the paging view to all edges.
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        pagingViewController.select(index: indexPage)
        let pagingIndexItem = self.pagingViewController(pagingViewController, pagingItemForIndex: indexPage) as PagingIndexItem
        self.title = pagingIndexItem.title
        
        // changeTheming
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeTheming), name: NSNotification.Name(rawValue: "changeTheming"), object: nil)
        changeTheming()
    }
    
    @objc func changeTheming() {
        appDelegate.changeTheming(self, tableView: nil, collectionView: nil, form: true)
        
        pagingViewController.backgroundColor = NCBrandColor.sharedInstance.backgroundForm
        pagingViewController.selectedBackgroundColor = NCBrandColor.sharedInstance.backgroundForm
        pagingViewController.textColor = NCBrandColor.sharedInstance.textView
        pagingViewController.selectedTextColor = NCBrandColor.sharedInstance.textView
        pagingViewController.indicatorColor = NCBrandColor.sharedInstance.brand
        (pagingViewController.view as! NCSharePagingView).setupConstraints()
        pagingViewController.reloadMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pagingViewController.menuItemSize = .fixed(width: self.view.bounds.width/3, height: 40)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        appDelegate.activeMain?.reloadDatasource(self.appDelegate.activeMain?.serverUrl, ocId: nil, action: Int(k_action_NULL))
        appDelegate.activeFavorites?.reloadDatasource(nil, action: Int(k_action_NULL))
        appDelegate.activeOffline?.loadDatasource()
    }
    
    @objc func exitTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - PagingViewController Delegate

extension NCSharePaging: PagingViewControllerDelegate {
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, willScrollToItem pagingItem: T, startingViewController: UIViewController, destinationViewController: UIViewController) where T : PagingItem, T : Comparable, T : Hashable {
        
        guard let item = pagingItem as? PagingIndexItem else { return }
        self.title = item.title
    }
}

// MARK: - PagingViewController DataSource

extension NCSharePaging: PagingViewControllerDataSource {
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
        
        let height = pagingViewController.options.menuHeight + NCSharePagingView.HeaderHeight
        
        switch index {
        case 0:
            let viewController = UIStoryboard(name: "NCActivity", bundle: nil).instantiateInitialViewController() as! NCActivity
            viewController.insets = UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0)
            viewController.didSelectItemEnable = false
            viewController.filterFileId = metadata!.fileId
            viewController.objectType = "files"
            return viewController
        case 1:
            let viewController = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "comments") as! NCShareComments
            viewController.metadata = metadata!
            viewController.height = height
            return viewController
        case 2:
            let viewController = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "sharing") as! NCShare
            viewController.metadata = metadata!
            viewController.height = height
            return viewController
        default:
            return UIViewController()
        }
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
        switch index {
        case 0:
            return PagingIndexItem(index: index, title: NSLocalizedString("_activity_", comment: "")) as! T
        case 1:
            return PagingIndexItem(index: index, title: NSLocalizedString("_comments_", comment: "")) as! T
        case 2:
            return PagingIndexItem(index: index, title: NSLocalizedString("_sharing_", comment: "")) as! T
        default:
            return PagingIndexItem(index: index, title: "") as! T
        }
    }
    
    func numberOfViewControllers<T>(in: PagingViewController<T>) -> Int{
        return 3
    }
}

// MARK: - Header

class NCShareHeaderViewController: PagingViewController<PagingIndexItem> {
    
    public var image: UIImage?
    public var metadata: tableMetadata?
    
    override func loadView() {
        view = NCSharePagingView(
            options: options,
            collectionView: collectionView,
            pageView: pageViewController.view,
            metadata: metadata
        )
    }
}

class NCSharePagingView: PagingView {
    
    static let HeaderHeight: CGFloat = 200
    var metadata: tableMetadata?
    
    var headerHeightConstraint: NSLayoutConstraint?
    
    public init(options: Parchment.PagingOptions, collectionView: UICollectionView, pageView: UIView, metadata: tableMetadata?) {
        super.init(options: options, collectionView: collectionView, pageView: pageView)
        
        self.metadata = metadata
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupConstraints() {
        
        let headerView = Bundle.main.loadNibNamed("NCShareHeaderView", owner: self, options: nil)?.first as! NCShareHeaderView
        headerView.backgroundColor = NCBrandColor.sharedInstance.backgroundForm
        headerView.ocId = metadata!.ocId
        
        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, fileNameView: metadata!.fileNameView)) {
            headerView.imageView.image = UIImage.init(contentsOfFile: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, fileNameView: metadata!.fileNameView))
        } else {
            if metadata!.iconName.count > 0 {
                headerView.imageView.image = UIImage.init(named: metadata!.iconName)
            } else if metadata!.directory {
                let image = UIImage.init(named: "folder")!
                headerView.imageView.image = CCGraphics.changeThemingColorImage(image, width: image.size.width*2, height: image.size.height*2, color: NCBrandColor.sharedInstance.brandElement)
            } else {
                headerView.imageView.image = UIImage.init(named: "file")
            }
        }
        headerView.fileName.text = metadata?.fileNameView
        headerView.fileName.textColor = NCBrandColor.sharedInstance.textView
        if metadata!.favorite {
            headerView.favorite.setImage(CCGraphics.changeThemingColorImage(UIImage.init(named: "favorite"), width: 40, height: 40, color: NCBrandColor.sharedInstance.yellowFavorite), for: .normal)
        } else {
            headerView.favorite.setImage(CCGraphics.changeThemingColorImage(UIImage.init(named: "favorite"), width: 40, height: 40, color: NCBrandColor.sharedInstance.textInfo), for: .normal)
        }
        headerView.info.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
        addSubview(headerView)
        
        pageView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        headerHeightConstraint = headerView.heightAnchor.constraint(
            equalToConstant: NCSharePagingView.HeaderHeight
        )
        headerHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: options.menuHeight),
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            pageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            pageView.topAnchor.constraint(equalTo: topAnchor, constant: 10)
        ])
    }
}

class NCShareHeaderView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var favorite: UIButton!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ocId = ""

    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        
        if let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "ocId == %@", ocId)) {
            
            NCCommunication.sharedInstance.setFavorite(urlString: appDelegate.activeUrl, fileName: metadata.fileName, favorite: !metadata.favorite, account: metadata.account) { (account, errorCode, errorDescription) in
                if errorCode == 0 {
                    NCManageDatabase.sharedInstance.setMetadataFavorite(ocId: metadata.ocId, favorite: !metadata.favorite)
                    if !metadata.favorite {
                        self.favorite.setImage(CCGraphics.changeThemingColorImage(UIImage.init(named: "favorite"), width: 40, height: 40, color: NCBrandColor.sharedInstance.yellowFavorite), for: .normal)
                    } else {
                        self.favorite.setImage(CCGraphics.changeThemingColorImage(UIImage.init(named: "favorite"), width: 40, height: 40, color: NCBrandColor.sharedInstance.textInfo), for: .normal)
                    }
                    self.appDelegate.activeMain?.reloadDatasource(self.appDelegate.activeMain?.serverUrl, ocId: nil, action: Int(k_action_NULL))
                    self.appDelegate.activeFavorites?.reloadDatasource(nil, action: Int(k_action_NULL))
                }
            }
        }
    }
}
