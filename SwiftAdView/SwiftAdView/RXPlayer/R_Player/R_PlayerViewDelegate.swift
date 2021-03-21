
import Foundation
import UIKit

public protocol R_CustomMenuDelegate: class {
    /// 自定义右上角按钮点击操作
    func showCustomMuneView() -> UIView?
}

public extension R_CustomMenuDelegate {
    func showCustomMuneView() -> UIView? {
        return nil
    }
}

public protocol R_PlayerDelegate: class {
    func customActionsBeforePlay()
    /// 开始播放
    func startPlay()
    /// 重试
    func retryToPlayVideo(url: URL?)
    /// 播放失败
    func playVideoFailed(url: URL?, player: R_PlayerView)
    /// 播放进度
    func playerProgress(progress: Float, currentPlayTime: Float)
    /// 当前播放的视频播放完成时调用
    func currentVideoPlayToEnd(url: URL?, isPlayingloaclFile: Bool)
}

public extension R_PlayerDelegate {
    func customActionsBeforePlay() {}
    /// 开始播放
    func startPlay() {}
    /// 重试播放
    func retryToPlayVideo(url: URL?) { }
    /// 播放失败
    func playVideoFailed(url: URL?, player: R_PlayerView) {}
    /// 播放进度
    func playerProgress(progress: Float, currentPlayTime: Float) {}
    /// 播放完成
    func currentVideoPlayToEnd(url: URL??, isPlayingloaclFile: Bool) { }
}




