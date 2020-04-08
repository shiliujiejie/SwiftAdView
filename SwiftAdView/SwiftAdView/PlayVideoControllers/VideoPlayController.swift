//
//  VideoPlayController.swift
//  CaoLiuApp
//
//  Created by mac on 2019/3/11.
//  Copyright © 2019年 AnakinChen Network Technology. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVKit
import Photos

/// 个人中心弹出播放页
class VideoPlayController: UIViewController {

    var currentIndex:Int = 0
    var currentPlayIndex: Int = 0
    var isFirstIn = true
    
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
    lazy var playerView: PlayerView = {
        let player = PlayerView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
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
   
    var videos = ["http://192.168.1.124:50009/121.m3u8","http://youku163.zuida-bofang.com/20180905/13609_155264ac/index.m3u8","https://github.com/shiliujiejie/adResource/raw/master/2.mp4", "https://github.com/shiliujiejie/adResource/raw/master/1.mp4", "https://github.com/shiliujiejie/adResource/raw/master/3.mp4"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        view.backgroundColor = UIColor.clear
        setUpUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //playerView.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.pause()
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
        if playerView.player != nil {
             let fullPlayer = FullScreenPlayController()
            fullPlayer.player = playerView.player!
            fullPlayer.modalPresentationStyle = .fullScreen
            present(fullPlayer, animated: false, completion: nil)
        }
    }
    
}

// MARK: - PlayerViewDelegate
extension VideoPlayController: PlayerViewDelegate {

    func playerProgress(progress: Float, currentPlayTime: Float) {
        print("progress  --- \(progress) currentPlayTime = \(currentPlayTime) currentTimeString = \(PlayerView.formatTimPosition(position: Int(currentPlayTime), duration: Int(playerView.videoDuration))) videoTime_length = \(PlayerView.formatTimDuration(duration: Int(playerView.videoDuration)))")
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
    func currentUrlPlayToEnd(url: URL?, player: PlayerView) {
           print("currentUrlPlayToEnd = url: \(url!.absoluteString)")
           player.replay()
       }
    func playVideoFailed(url: URL?, player: PlayerView) {
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
extension VideoPlayController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PresentPlayCell.cellId, for: indexPath) as! PresentPlayCell
        if indexPath.row == currentIndex && isFirstIn {
            if let url = URL(string: videos[indexPath.row]) {
                self.playerView.startPlay(url: url, in: cell.bgImage)
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
extension VideoPlayController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIScreen.main.bounds.size;
    }
}

extension VideoPlayController:UIScrollViewDelegate {
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
                            self.playerView.startPlay(url: url, in: cell.bgImage)
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
private extension VideoPlayController {
    
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

