

import UIKit

class CategrayController: UIViewController {
/// 是否编辑
    var isEdit = false {
        didSet {
            collectionView.reloadData()
        }
    }
    // 上部 我的频道
    private var homeTitles = [HomeNewsTitle]()
    // 下部 频道推荐数据
    private var categories = [HomeNewsTitle]()
    private let customLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (screenWidth - 50) * 0.25, height: 44)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        return layout
    }()
    private lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: customLayout)
        collection.backgroundColor = UIColor.white
        collection.showsHorizontalScrollIndicator = false
        collection.isPagingEnabled = true
        collection.bounces = false
        collection.delegate = self
        collection.dataSource = self
        
        return collection
    }()
   // @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        collectionView.frame = view.bounds
        // 从数据库中取出左右数据，赋值给 标题数组 titles
        homeTitles = NewsTitleTable().selectAll()
       
        // 注册 cell 和头部
        collectionView.register(UINib(nibName: "AddCategoryCell", bundle: Bundle.main), forCellWithReuseIdentifier: AddCategoryCell.cellId)
        collectionView.register(UINib(nibName: "ChannelRecommendCell", bundle: Bundle.main), forCellWithReuseIdentifier: ChannelRecommendCell.cellId)
       
        collectionView.register(UINib(nibName: "MyChannelReusableView", bundle: Bundle.main), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier:MyChannelReusableView.reuseId )
        collectionView.register(UINib(nibName: "ChannelRecommendReusableView", bundle: Bundle.main), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ChannelRecommendReusableView.reuseId )
         
        collectionView.allowsMultipleSelection = true
        collectionView.addGestureRecognizer(longPressRecognizer)
        for i in 0 ..< 20 {
            guard let newsCatee = NewsTitleCategory(rawValue: "news_hot") else { return  }
            let new = HomeNewsTitle.init(category: newsCatee, tip_new: i, default_add: i, web_url: "", concern_id: "", icon_url: "", flags:i, type: i, name: "index\(i)", selected: false)
            categories.append(new)
            self.collectionView.reloadData()
        }
    }
    
    /// 长按手势
    private lazy var longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressTarget))
    
    @objc private func longPressTarget(longPress: UILongPressGestureRecognizer) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "longPressTarget"), object: nil)
        // 选中的 点
        let selectedPoint = longPress.location(in: collectionView)
        // 转换成索引
        if let selectedIndexPath = collectionView.indexPathForItem(at: selectedPoint) {
            switch longPress.state {
            case .began:
                if isEdit && selectedIndexPath.section == 0 { // 选中的是上部的 cell,并且是可编辑状态
                    collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
                } else {
                    isEdit = true
                    collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
                }
            case .changed:
                // 固定第一、二个不能移动
                if selectedIndexPath.item <= 1 { collectionView.endInteractiveMovement(); break }
                collectionView.updateInteractiveMovementTargetPosition(longPress.location(in: longPressRecognizer.view))
            case .ended:
                collectionView.endInteractiveMovement()
            default:
                collectionView.cancelInteractiveMovement()
            }
        } else {
            // 判断点是否在 collectionView 上
            if selectedPoint.x < collectionView.bounds.minX || selectedPoint.x > collectionView.bounds.maxX || selectedPoint.y < collectionView.bounds.minY || selectedPoint.y > collectionView.bounds.maxY  {
                collectionView.endInteractiveMovement()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 关闭按钮
    @IBAction func closeAddCategoryButtonClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - MyChannelReusableViewDelegate
extension CategrayController: AddCategoryCellDelagate {
    /// 删除按钮点击
    func deleteCategoryButtonClicked(of cell: AddCategoryCell) {
        // 上部删除，下部添加
        let indexPath = collectionView.indexPath(for: cell)
        categories.insert(homeTitles[indexPath!.item], at: 0)
        collectionView.insertItems(at: [IndexPath(item: 0, section: 1)])
        homeTitles.remove(at: indexPath!.item)
        collectionView.deleteItems(at: [IndexPath(item: indexPath!.item, section: 0)])
    }

}

extension CategrayController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    /// 头部
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if indexPath.section == 0 {
            let channelResableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyChannelReusableView.reuseId, for: indexPath) as! MyChannelReusableView
            // 点击了编辑 / 完成 按钮
            channelResableView.channelReusableViewEditButtonClicked = { [weak self] (sender) in
                self!.isEdit = sender.isSelected
                if !sender.isSelected { collectionView.endInteractiveMovement() }
            }
           // channelResableView.frame.width = screenWidth - 15.0
            return channelResableView
        } else {
            let channelRecommendReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ChannelRecommendReusableView.reuseId, for: indexPath) as! ChannelRecommendReusableView
           // channelRecommendReusableView.frame.width = screenWidth - 15.0
            return channelRecommendReusableView
        }
    }
    
    /// headerView 的大小
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: screenWidth, height: 50)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? homeTitles.count : categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddCategoryCell.cellId, for: indexPath) as! AddCategoryCell
            cell.titleButton.setTitle(homeTitles[indexPath.item].name, for: .normal)
            cell.isEdit = isEdit
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelRecommendCell.cellId, for: indexPath) as! ChannelRecommendCell
            cell.titleButton.setTitle(categories[indexPath.item].name, for: .normal)
            return cell
        }
    }
    
    /// 点击了某一个 cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 点击上面一组，不做任何操作，点击下面一组的cell 会添加到上面的组里
        guard indexPath.section == 1 else { return }
        homeTitles.append(categories[indexPath.item]) // 添加
        collectionView.insertItems(at: [IndexPath(item: homeTitles.count - 1, section: 0)])
        categories.remove(at: indexPath.item)
        collectionView.deleteItems(at: [IndexPath(item: indexPath.item, section: 1)])
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// 移动 cell
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // 固定第一、二个不能移动
        if destinationIndexPath.item <= 1 {
            collectionView.endInteractiveMovement()
            collectionView.reloadData()
            return
        }
        // 取出需要移动的 cell
        let title = homeTitles[sourceIndexPath.item]
        homeTitles.remove(at: sourceIndexPath.item)
        // 移动 cell
        if isEdit && sourceIndexPath.section == 0 {
            // 说明移动前后都在 第一组
            if destinationIndexPath.section == 0 {
                homeTitles.insert(title, at: destinationIndexPath.item)
            } else { // 说明移动后在 第二组
                categories.insert(title, at: destinationIndexPath.item)
            }
        }
    }
    
    /// 每个 cell 之间的间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
}

