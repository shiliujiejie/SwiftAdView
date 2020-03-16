//
//  VideoTableController.swift
//  SwiftAdView
//
//  Created by mac on 2020-03-14.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit
import AVKit

class VideoTableController: UIViewController {
   
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
    /// 这里用UITableView 来做， 也可以使用UICollectionView 一样的效果（纯属 个人习惯）
    lazy var tableView: UITableView = {
        let table = UITableView.init(frame: view.bounds, style: .plain)
        table.backgroundColor = UIColor.white
        table.delegate = self
        table.dataSource = self
        table.bounces = false
        table.showsVerticalScrollIndicator = false
        table.scrollsToTop = false
        table.register(TablePlayCell.classForCoder(), forCellReuseIdentifier: TablePlayCell.cellId)
        return table
    }()
    let tableHeader: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth*9/16))
        view.backgroundColor = UIColor.darkText
        return view
    }()
    let timelabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(white: 0, alpha: 0.1)
        label.textColor = UIColor.white
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 12)
        label.layer.cornerRadius = 2
        label.layer.masksToBounds = true
        return label
    }()
    
    lazy var playerView: PlayerView = {
        let player = PlayerView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth*9/16))
        player.controlViewBottomInset = 0
        player.progressHeight = 1.5
        player.controlViewHeight = 50
        player.loadingBarColor = UIColor.white
        player.progressTintColor = UIColor.blue
        player.progreesStrackTintColor = UIColor(white: 0.89, alpha: 1.0)
        player.loadingBarHeight = 3.0
        player.minTimeForDragProgress = 120   /// 进度条 可以拖动的视频 最短要求 180秒
        player.delegate = self
        return player
    }()
    lazy var fullPlayer: FullScreenPlayController = {
        let playerVc = FullScreenPlayController()
        return playerVc
    }()
     var videos = ["http://youku163.zuida-bofang.com/20180905/13609_155264ac/index.m3u8","http://vcdn11.fzyccw.com/media/video-preview/d6a/d6a4fa9f270adcb523fc3923ec5d62ca/perview.m3u8","http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4c0c9e59031868222924048327/f0.mp4","https://github.com/shiliujiejie/adResource/raw/master/2.mp4", "https://github.com/shiliujiejie/adResource/raw/master/1.mp4", "https://github.com/shiliujiejie/adResource/raw/master/3.mp4"]
    var currentIndex: Int = 0
    
    /// 在头部播放 或在cell中播放
    var playInHeader: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor.darkText
        view.addSubview(tableHeader)
        view.addSubview(tableView)
        tableHeader.addSubview(timelabel)
        
        playerView.startPlay(url: URL(string: videos[0]), in: tableHeader)
        view.addSubview(leftBackButton)
        view.addSubview(rightBackButton)
        layoutPageSubviews()
        ///
        playInHeader = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.pause()
    }
    
    @objc func backButtonClick() {
        self.navigationController?.popViewController(animated: true)
    }
    @objc func rightButtonClick() {
        if playerView.player != nil {
            fullPlayer.player = playerView.player!
        } else {
            fullPlayer.player = AVPlayer(url: URL(string: videos[currentIndex])!)
        }
       
        fullPlayer.modalPresentationStyle = .fullScreen
        present(fullPlayer, animated: false, completion: nil)
    }
    
    func playNextVideo(_ index: Int) {
        if currentIndex != index {
            playerView.stopPlaying()
            playerView.startPlay(url: URL(string: videos[index]), in: tableHeader)
            currentIndex = index
        }
    }
    

}

extension VideoTableController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (screenWidth - 10) * 9/16 + 20
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TablePlayCell.cellId, for: indexPath) as! TablePlayCell
        cell.playActionHandle = { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.playInHeader {
                 strongSelf.playNextVideo(indexPath.row)
            } else {
                strongSelf.playerView.startPlay(url: URL(string: strongSelf.videos[indexPath.row]), in: cell.bgImage)
                strongSelf.currentIndex = indexPath.row
            }
           
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}

// MARK: - PlayerViewDelegate
extension VideoTableController: PlayerViewDelegate {

    func playerProgress(progress: Float, currentPlayTime: Float) {
        //print("progress  --- \(progress) currentPlayTime = \(currentPlayTime) currentTimeString = \(playerView.formatTimPosition(position: Int(currentPlayTime), duration: Int(playerView.videoDuration))) videoTime_length = \(playerView.formatTimDuration(duration: Int(playerView.videoDuration)))")
        let currentTimestr = playerView.formatTimPosition(position: Int(currentPlayTime), duration: Int(playerView.videoDuration))
        let durationStr = playerView.formatTimDuration(duration: Int(playerView.videoDuration))
        timelabel.isHidden = false
        timelabel.text = "\(currentTimestr) | \(durationStr)"
    }
    func customActionsBeforePlay() {
        print("customActionsBeforePlay ---- Exp: remove Failed Shower View")
        timelabel.text = "00:00 | 00:00"
    }
    func loadingPlayResource() {
        print("loadingPlayResource")
    }
    func readyToPlay() {
        print("readyToPlay")
    }
    func startPlay() {
        print("startPlay")
        tableHeader.bringSubviewToFront(timelabel)
    }
    func currentUrlPlayToEnd(url: URL?, player: PlayerView) {
           print("currentUrlPlayToEnd = url: \(url!.absoluteString)")
           player.replay()
       }
    func playVideoFailed(url: URL?, player: PlayerView) {
        print("playVideoFailed")
        timelabel.isHidden = true
    }
    func doubleTapGestureAt(point: CGPoint) {
        print("doubleTapGestureAction")
    }
    func dragingProgress(isDraging: Bool, to progress: Float?) {
        print("isdraging = \(isDraging) dragingProgress = \(progress ?? 0)")
    }
}

// MARK: - Layout
private extension VideoTableController {
    
    func layoutPageSubviews() {
        layoutTableView()
        layoutLeftBackButton()
        layoutRightBackButton()
        layouTimeLabel()
    }
    func layoutTableView() {
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(tableHeader.snp.bottom)
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
    func layouTimeLabel() {
        timelabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(-10)
            make.bottom.equalTo(-7.5)
            make.height.equalTo(16)
        }
    }
}
