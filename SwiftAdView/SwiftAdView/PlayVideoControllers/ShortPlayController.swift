
import UIKit
import AssetsLibrary
import AVKit
import Photos
import GCDWebServer

/// 个人中心弹出播放页
class ShortPlayController: UIViewController {

    var currentIndex:Int = 0
    var currentPlayIndex: Int = 0
    var isFirstIn = true
    
    private var port: UInt = 8095
    let server = GCDWebServer()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    lazy var leftBackButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "navBackWhite"), for: .normal)
        button.backgroundColor = UIColor(white: 0.9, alpha: 0.1)
        button.layer.cornerRadius = 17.5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(backButtonClick), for: .touchUpInside)
        return button
    }()
    lazy var rightBackButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "fullscreen"), for: .normal)
        button.backgroundColor = UIColor(white: 0.9, alpha: 0.1)
        button.layer.cornerRadius = 17.5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(rightButtonClick), for: .touchUpInside)
        return button
    }()
    lazy var playerView: X_PlayerView = {
        let player = X_PlayerView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        player.controlViewBottomInset = safeAreaBottomHeight + 49
        player.delegate = self
        return player
    }()
    let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: screenWidth, height: screenHeight)
        //每个Item之间最小的间距
        layout.minimumInteritemSpacing = 0
        //每行之间最小的间距
        layout.minimumLineSpacing = 0
        return layout
    }()
    
    /// 这里用UICollectionView来做， 也可以使用UITableView 一样的效果（纯属 个人习惯）
    lazy var collection: UICollectionView = {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.bounces = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.scrollsToTop = false
        collectionView.register(PresentPlayCell.classForCoder(), forCellWithReuseIdentifier: PresentPlayCell.cellId)
        return collectionView
    }()
   
    var videos = ["http://youku163.zuida-bofang.com/20180905/13609_155264ac/index.m3u8","http://yun.kubo-zy-youku.com/20181112/BULbB7PC/index.m3u8","http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4c0c9e59031868222924048327/f0.mp4","https://github.com/shiliujiejie/adResource/raw/master/2.mp4","https://video.kkyun-iqiyi.com/20180301/WNvThg3j/index.m3u8", "https://vs1.baduziyuan.com/20180106/5hykgzke/800kb/hls/index.m3u8","http://yun.kubo-zy-youku.com/20181112/BULbB7PC/index.m3u8","https://github.com/shiliujiejie/adResource/raw/master/3.mp4"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        view.backgroundColor = UIColor.clear
        if server.isRunning {
            server.stop()
        }
        setUpUI()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //playerView.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.pause()
        if server.isRunning {
            server.stop()
        }
    }
   
    private func setUpUI() {
        //commentbgView.addSubview(videoCommentView)
        if #available(iOS 11.0, *) {
            collection.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        self.view.addSubview(self.collection)
        self.view.addSubview(self.leftBackButton)
        view.addSubview(rightBackButton)
        self.layoutPageSubviews()
    }
    @objc func backButtonClick() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func rightButtonClick() {
      
//        playerView.resetRate(rate: 1.5)
//        return
        if playerView.player != nil {
             let fullPlayer = X_FullScreenPlayController()
            fullPlayer.player = playerView.player!
            fullPlayer.modalPresentationStyle = .fullScreen
            present(fullPlayer, animated: false, completion: nil)
        }
    }
    func playVideo(_ url: URL,in view: UIView) {
        let identifer = url.absoluteString.md5()
        if server.isRunning {
            server.stop()
        }
        if DownLoadHelper.filesIsAllExist(identifer) { /// 已缓存
            let pathq = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(identifer).path
            server.addGETHandler(forBasePath: "/", directoryPath: pathq, indexFilename: "\(identifer).m3u8", cacheAge: 3600, allowRangeRequests: true)
            
            server.start(withPort: port, bonjourName: nil)
            
            if server.serverURL != nil {
                let videoLocalUrl = "\(server.serverURL!.absoluteString)\(identifer).m3u8"
                print("videoLocalServerUrl == \(videoLocalUrl)")
                playerView.startPlay(url: URL(string: videoLocalUrl), in: view)
            }
        } else {
            playerView.startPlay(url: url, in: view, uri: nil, cache: true)
        }
    }
    
}

// MARK: - X_PlayerViewDelegate
extension ShortPlayController: X_PlayerViewDelegate {

    func playerProgress(progress: Float, currentPlayTime: Float) {
        print("progress  --- \(progress) currentPlayTime = \(currentPlayTime) currentTimeString = \(RXPublicConfig.formatTimPosition(position: Int(currentPlayTime), duration: Int(playerView.videoDuration))) videoTime_length = \(RXPublicConfig.formatTimDuration(duration: Int(playerView.videoDuration)))")
    }
    func customActionsBeforePlay() {
        print("customActionsBeforePlay ---- Exp: remove Failed Shower View")
    }
    func loadingPlayResource() {
        print("loadingPlayResource")
    }
    func readyToPlay() {
        print("readyToPlay")
    }
    func startPlay() {
        print("startPlay")
    }
    func currentUrlPlayToEnd(url: URL?, player: X_PlayerView) {
           print("currentUrlPlayToEnd = url: \(url!.absoluteString)")
           player.replay()
       }
    func playVideoFailed(url: URL?, player: X_PlayerView) {
        print("playVideoFailed")
    }
    func doubleTapGestureAt(point: CGPoint) {
        print("doubleTapGestureAction")
    }
    func dragingProgress(isDraging: Bool, to progress: Float?) {
        print("isdraging = \(isDraging) dragingProgress = \(progress ?? 0)")
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension ShortPlayController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PresentPlayCell.cellId, for: indexPath) as! PresentPlayCell
        if indexPath.row == currentIndex && isFirstIn {
            if let url = URL(string: videos[indexPath.row]) {
                //self.playerView.startPlay(url: url, in: cell.bgImage)
                playVideo(url, in: cell.bgImage)
                self.isFirstIn = false
                self.currentPlayIndex = self.currentIndex
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}


// MARK: - UICollectionViewDelegateFlowLayout
extension ShortPlayController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIScreen.main.bounds.size;
    }
}

extension ShortPlayController:UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        DispatchQueue.main.async {
            /// 禁用手势
            let translatedPoint = scrollView.panGestureRecognizer.translation(in: scrollView)
            
            if translatedPoint.y < -50 && self.currentIndex < (self.videos.count - 1) {
                /// 上滑
                self.currentIndex += 1
            }
            if translatedPoint.y > 50 && self.currentIndex > 0 {
                /// 下滑
                self.currentIndex -= 1
            }
            let indexPath = IndexPath(row: self.currentIndex, section: 0)
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                if self.videos.count > indexPath.row {
                    self.collection.scrollToItem(at: indexPath, at: .top, animated: true)
                }
            }, completion: { finished in
                scrollView.panGestureRecognizer.isEnabled = true
                if let cell = self.collection.cellForItem(at: indexPath) as? PresentPlayCell {
                    if self.currentPlayIndex != self.currentIndex { // 上下滑动
                        if let url =  URL(string: self.videos[indexPath.row]) {
                           // self.playerView.startPlay(url: url, in: cell.bgImage)
                            self.playVideo(url, in: cell.bgImage)
                            self.isFirstIn = false
                            self.currentPlayIndex = self.currentIndex
                        }
                    }
                }
            })
        }
    }
}




// MARK: - Layout
private extension ShortPlayController {
    
    func layoutPageSubviews() {
        layoutLeftBackButton()
        layoutRightBackButton()
        layoutCollection()
    }
    
    func layoutCollection() {
        collection.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    func layoutLeftBackButton() {
        leftBackButton.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.top.equalTo(screenHeight >= 812 ? 40 : 20)
            make.width.height.equalTo(35)
        }
    }
    
    func layoutRightBackButton() {
        rightBackButton.snp.makeConstraints { (make) in
            make.trailing.equalTo(-16)
            make.top.equalTo(screenHeight >= 812 ? 40 : 20)
            make.width.height.equalTo(35)
        }
    }
}

