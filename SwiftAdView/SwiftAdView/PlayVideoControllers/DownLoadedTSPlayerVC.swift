import UIKit
import AVFoundation
import GCDWebServer

/// 播放本地视频
/// 模拟播放已下载好的本地视频
class DownLoadedVideoPlayerVC: UIViewController {
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    private var port: UInt = 8095
    var identifer: String = ""
    let server = GCDWebServer()
    
    /// 播放本地文件的时候，状态栏颜色样式与是否全屏无关 （默认全屏）
    override var preferredStatusBarStyle: UIStatusBarStyle {
        let orirntation = UIApplication.shared.statusBarOrientation
        if  orirntation == UIInterfaceOrientation.landscapeLeft || orirntation == UIInterfaceOrientation.landscapeRight {
            return .lightContent
        }
        return .default
    }
    var avItem: AVPlayerItem?
    
    lazy var videoPlayer: R_PlayerView = {
        let player = R_PlayerView(frame: self.view.frame)
        player.delegate = self
        return player
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        if server.isRunning {
            server.stop()
        }
        //videoPlayer.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        playLocal_2_func()
    }
    
    //MARK: - 本地服务器搭建
    private func playLocal_2_func() {
        let pathq = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(identifer).path
        server.addGETHandler(forBasePath: "/", directoryPath: pathq, indexFilename: "\(identifer).m3u8", cacheAge: 3600, allowRangeRequests: true)
        
        server.start(withPort: port, bonjourName: nil)
        if server.serverURL == nil { return }
        
        let videoLocalUrl = "\(server.serverURL!.absoluteString)\(identifer).m3u8"
        print("videoLocalUrl == \(videoLocalUrl)")
        if let urlLocal = URL(string: videoLocalUrl) {
            videoPlayer.playVideoInFullscreen(url: urlLocal, in: view, title: pathq)
            videoPlayer.playLocalFileVideoCloseCallBack = { [weak self] (playValue) in
                // 退出时，关闭本地服务器
                self?.server.stop()
                self?.navigationController?.popViewController(animated: false)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if server.isRunning {
            server.stop()
        }
    }
}

// MARK: - R_PlayerDelegate
extension DownLoadedVideoPlayerVC: R_PlayerDelegate {
    
    func startPlay() {
         
    }
    func retryToPlayVideo(url: URL?) {
        
    }
    func playerProgress(progress: Float, currentPlayTime: Float) {
        
    }
    func currentVideoPlayToEnd(url: URL??, isPlayingloaclFile: Bool) {
        
    }
}

