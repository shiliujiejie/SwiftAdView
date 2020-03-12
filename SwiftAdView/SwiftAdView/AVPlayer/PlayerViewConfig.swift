//
//  PlayerViewConfig.swift
//  SwiftAdView
//
//  Created by mac on 2020-03-11.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit

class PlayerViewConfig: NSObject {
    
    /// 操作栏底部 相对父视图的 距离
    var controlBarBottomInset: CGFloat = 40.0
    /// 加载动画颜色
    var loadingBarColor: UIColor? = UIColor.white
    /// 进度条 颜色
    var progressTintColor: UIColor? = UIColor(white: 0.85, alpha: 0.9)
    var progressBackgroundColor: UIColor? = UIColor(white: 0.5, alpha: 0.1)
    var controlViewColor: UIColor? = UIColor.clear
    /// 进度条高度 (不能高于 controlViewHeight )
    var progressHeight: CGFloat = 0.5
    /// 拖动时的进度条高度
    var selectedProgrossHight: CGFloat = 8.0
    /// 底部操作栏高度（操作栏高度会影响 进度条拖动手势的响应面积 从而影响 灵敏度 ，越高越敏度）
    var controlViewHeight:CGFloat = 45.0
}

public protocol PlayerViewDelegate: class {
    func customActionsBeforePlay()
    func loadingPlayResource()
    func readyToPlay()
    func startPlay()
    func playVideoFailed(url: URL?,player: PlayerView)
    func playerProgress(progress: Float, currentPlayTime: Float)
    func currentUrlPlayToEnd(url: URL?, player: PlayerView)
    func dragingProgress(isDraging: Bool, to progress: Float?)
    func doubleTapGestureAt(point: CGPoint)
}

public extension PlayerViewDelegate {
    /// 调用播放之前，要做的事 写在这个代理里面
    func customActionsBeforePlay() {}
    
    /// 加载播放资源
    func loadingPlayResource() {}
    /// 准备播放
    func readyToPlay() {}
    /// 开始播放
    func startPlay() {}
    /// 播放失败
    func playVideoFailed(url: URL?, player: PlayerView) {}
    /// 播放进度
    func playerProgress(progress: Float, currentPlayTime: Float) {}
    /// 当前链接 播放到 最后
    func currentUrlPlayToEnd(url: URL?, player: PlayerView) {}
    /// 是否正在拖动进度条，isDraging: true progress = 正要拖动的 进度 / false  progress = 最终进度 点
    func dragingProgress(isDraging: Bool, to progress: Float?) {}
    /// 双击手势
    func doubleTapGestureAt(point: CGPoint) {}
}

