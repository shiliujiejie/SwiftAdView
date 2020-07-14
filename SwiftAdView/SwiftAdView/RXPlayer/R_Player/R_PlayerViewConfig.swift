
import Foundation
import UIKit

/// 播放状态枚举
///
/// - Failed: 失败
/// - ReadyToPlay: 将要播放
/// - Unknown: 未知
/// - Buffering: 正在缓冲
/// - Playing: 播放
/// - Pause: 暂停
public enum PlayerStatus {
    case Failed
    case ReadyToPlay
    case Unknown
    case Buffering
    case Playing
    case Pause
}


public protocol R_CustomMuneDelegate: class {
    /// 自定义右上角按钮点击操作
    func showCustomMuneView() -> UIView?
    
    func customTopBarActions() -> [UIButton]?
}

public extension R_CustomMuneDelegate {
    
    func showCustomMuneView() -> UIView? {
        return nil
    }
    func customTopBarActions() -> [UIButton]? {
        return nil
    }
}

public protocol R_PlayerDelegate: class {
    
    /// 代理在外部处理网络问题
    func retryToPlayVideo(_ player: R_PlayerView, _ videoModel: RXVideoModel?, _ fatherView: UIView?)
    
    /// 当前播放的视频播放完成时调用
    ///
    /// - Parameters:
    ///   - videoModel: 当前播放完的本地视频的Model
    ///   - isPlayingDownLoadFile: 是否是播放的已下载视频
    func currentVideoPlayToEnd(_ videoModel: RXVideoModel?, _ isPlayingDownLoadFile: Bool)
}

public extension R_PlayerDelegate {
    func currentVideoPlayToEnd(_ videoModel: RXVideoModel?, _ isPlayingDownLoadFile: Bool) {
    }
}

/// 滑动手势的方向
enum PanDirection: Int {
    case PanDirectionHorizontal     //水平
    case PanDirectionVertical       //上下
}

public enum R_PlayerOrietation: Int {
    case orientationPortrait
    case orientationLeftAndRight
    case orientationAll
    
    public func getOrientSupports() -> UIInterfaceOrientationMask {
        switch self {
        case .orientationPortrait:
            return [.portrait]
        case .orientationLeftAndRight:
            return [.landscapeLeft, .landscapeRight]
        case .orientationAll:
            return [.portrait, .landscapeLeft, .landscapeRight]
        }
    }
}
public var orientationSupport: R_PlayerOrietation = .orientationPortrait

// log
public func NLog(_ item: Any, _ file: String = #file,  _ line: Int = #line, _ function: String = #function) {
    #if DEBUG
    print(file + ":\(line):" + function, item)
    #endif
}
