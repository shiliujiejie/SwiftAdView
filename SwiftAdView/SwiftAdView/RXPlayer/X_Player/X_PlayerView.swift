
import UIKit
import Foundation
import AVFoundation

public class X_PlayerView: UIView {
    
    private var playerStatu: PlayerStatus? {
        didSet {
            if playerStatu == .Playing {
                player?.play()
                player?.rate = rate
                pauseImg.isHidden = true
            }else if playerStatu == .Pause {
                player?.pause()
                player?.rate = 0.0
                pauseImg.isHidden = false
            }
        }
    }
    /// 暂停按钮
    private let pauseImg: UIImageView = {
        let image =  UIImageView(image: RXPublicConfig.foundImage(imageName: "pause"))
        image.isUserInteractionEnabled = true
        image.contentMode = .scaleAspectFit
        image.isHidden = true
        return image
    }()
    /// 播放控制View
    private var coverView: X_PlayerCoverView!
   
    /// 播放速率
    private var rate: Float = 1.0
    /// 加载进度
    private var loadedValue: Float = 0
    private var avItem: AVPlayerItem?
    private var playerTimerObserver: NSObject?
    private var playerLayer: AVPlayerLayer?
    
    /// 公开播放器，便于外部使用
    public var player: AVPlayer?
    
    /// 当前播放到 时间
    public var playedValue: Float = 0
    /// 视频总时长
    public var videoDuration: Float = 0
    
    public weak var delegate: X_PlayerViewDelegate?
    
    /// 播放链接
    public var playUrl: URL?
    /// 操作栏底部 相对父视图的 距离
    public var controlViewBottomInset: CGFloat = 0
    /// 加载动画颜色
    public var loadingBarColor: UIColor? = UIColor.white
    /// 加载动画线条粗细
    public var loadingBarHeight: CGFloat = 2.0
    /// 进度条 颜色
    public var progressTintColor: UIColor? = UIColor(white: 0.85, alpha: 0.9)
    public var progressBackgroundColor: UIColor? = UIColor.clear
    public var progreesStrackTintColor: UIColor? = UIColor(white: 0.5, alpha: 0.5)
    /// 操作栏背景色
    public var controlViewColor: UIColor? = UIColor.clear
    /// 进度条高度 (不能高于 controlViewHeight )
    public var progressHeight: CGFloat = 0.5
    /// 拖动时的进度条高度
    public var selectedProgrossHight: CGFloat = 6.0
    /// 底部操作栏高度（操作栏高度会影响 进度条拖动手势的响应面积 从而影响 灵敏度 ，越高越敏度）
    public var controlViewHeight: CGFloat = 50.0
    /// The minimum time required to drag a progress bar (Unit: second)
    public var minTimeForDragProgress: Float = 30.0
    /// 操作栏是否带阴影
    public var controlViewCoverLayer: Bool = true
    /// 是否是预览 与 playerIsUserInteractionEnabled 一起使用
    public var isPerView: Bool = false
    /// 播放时缓存
    public var cacheWhenPlaying: Bool = false
    
    deinit {
        print("播放器释放")
        RXM3u8ResourceLoader.shared.interruptPlay()
        NotificationCenter.default.removeObserver(self)
        realeasePlayer()
    }
   
    required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        // 注册APP被挂起 + 进入前台通知
        NotificationCenter.default.addObserver(self, selector: #selector(applicationResignActivity(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActivity(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    /// KVO 监听播放狀態
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let avItem = object as? AVPlayerItem else {
            return
        }
        if keyPath == "status" {
            if avItem.status == .readyToPlay {
                playerStatu = .ReadyToPlay
                coverView.draging = false
                coverView.stopLoading()
                delegate?.readyToPlay()
            } else if avItem.status == .unknown || avItem.status == .failed {
                //视频加载失败，或者未知原因
                playerStatu = .Failed
                coverView.stopLoading()
                delegate?.playVideoFailed(url: playUrl, player: self)
            }
        } else if keyPath == "loadedTimeRanges" {
            updateLoadingProgress(avItem: avItem)
        } else if keyPath == "playbackBufferEmpty" {   // 监听播放器正在缓冲数据
            playerStatu = .Buffering
            delegate?.loadingPlayResource()
        } else if keyPath == "playbackLikelyToKeepUp" {  //监听视频缓冲达到可以播放的狀態
            delegate?.startPlay()
            updateTimeLableLayout(avItem: avItem)
        }
    }
    /// 暂停⏸️
    public func pause() {
        playerStatu = .Pause
    }
    /// 播放
    public func play() {
        playerStatu = .Playing
    }
    /// 重播
    public func replay() {
        avItem?.seek(to: CMTime.zero)
        coverView?.progressView.setProgress(0, animated: false)
        playerStatu = .Playing
    }
    /// 停止播放
    public func stopPlaying() {
        player?.rate = 0
        realeasePlayer()
    }
    /// 设置播放速度： effective range [0.5 - 2.0]
    public func resetRate(rate: Float) {
        if rate < 0.5 || rate > 2.0 { return }
        if self.rate == rate { return }
        player?.rate = rate
        self.rate = rate
    }
    public func playerIsUserInteractionEnabled(_ enable: Bool) {
        coverView.isUserInteractionEnabled = enable
        coverView.controlView.isUserInteractionEnabled = enable
        coverView.progressView.progressTintColor = enable ? progressTintColor : .clear
        coverView.progressView.trackTintColor = enable ? progreesStrackTintColor : .clear
        coverView.progressView.backgroundColor = enable ? progressBackgroundColor : .clear
        pauseImg.alpha = enable ? 1 : 0
    }
    /**
     播放统一调用 :
     url:   视频链接 （m3u8支持本地缓存）
     view:  播放器view的父视图
     uri:   跟后端约定好的解密密钥 （可有可无，看项目需求）
     cache: 是否边播边缓存
     */
    public func startPlay(url: URL?, in view: UIView, uri: String? = nil, cache: Bool? = false) {
        delegate?.customActionsBeforePlay()
        realeasePlayer()
        guard let trueUrl = url else {
            delegate?.playVideoFailed(url: url, player: self)
            return
        }
        
        if view.subviews.contains(self) { return }
    
        playUrl = trueUrl
        cacheWhenPlaying = cache ?? false
        if coverView != nil {
            coverView.removeFromSuperview()
        }
        if trueUrl.absoluteString.contains(".m3u8") {
            avItem = RXM3u8ResourceLoader.shared.playerItem(with: trueUrl, uriKey: uri, cacheWhenPlaying: cache)
        } else {
            /// 其他文件格式，这里处理
            let urlAsset = AVURLAsset(url: trueUrl, options: nil)
            avItem = AVPlayerItem(asset: urlAsset)
            RXM3u8ResourceLoader.shared.interruptPlay()
        }
        
        player = AVPlayer(playerItem: avItem!)
        playerLayer = AVPlayerLayer(player: player!)
        playerLayer?.frame = self.bounds
        playerLayer?.videoGravity = .resizeAspect
        self.layer.addSublayer(playerLayer!)

        coverView = X_PlayerCoverView(config: loadConfig())
        coverView?.delegate = self
        
        view.addSubview(self)
        self.addSubview(pauseImg)
        self.addSubview(coverView)
        
        layoutPageSubviews()
        addPlayerObserver()
        playerStatu = .Playing
       // player?.play()
        if !isPerView {
           coverView.startLoading()
        }
        coverView.controlView.isUserInteractionEnabled = false
        listenTothePlayer()
    }
    
    private func loadConfig() -> X_PlayerViewConfig {
        let config = X_PlayerViewConfig()
        config.controlBarBottomInset = controlViewBottomInset
        config.controlViewColor = controlViewColor
        config.loadingBarColor = loadingBarColor
        config.progressBackgroundColor = progressBackgroundColor
        config.progressTintColor = progressTintColor
        config.progreesStrackTintColor = progreesStrackTintColor
        config.progressHeight = progressHeight
        config.selectedProgrossHight = selectedProgrossHight
        config.controlViewHeight = controlViewHeight
        config.loadingBarHeight = loadingBarHeight
        config.controlViewCoverLayer = controlViewCoverLayer
        if progressHeight > controlViewHeight {
            config.controlViewHeight = progressHeight
        }
        if loadingBarHeight > 10.0 {
            config.loadingBarHeight = 10.0
        }
        return config
    }
    /// 销毁播放器源
    private func realeasePlayer() {
        coverView?.progressView.setProgress(0, animated: false)
        pauseImg.isHidden = true
        avItem?.removeObserver(self, forKeyPath: "status")
        avItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        avItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        avItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        player?.cancelPendingPrerolls()
        avItem = nil
        rate = 1.0
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerLayer?.removeFromSuperlayer()
        layer.removeAllAnimations()
        removeFromSuperview()
    }
    private func addPlayerObserver() {
        guard let avItem = self.avItem else {return}
        ///注册通知之前，需要先移除对应的通知，因为添加多此观察，方法会调用多次
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playToEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avItem)
        avItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        avItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        avItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
        avItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    private func updateLoadingProgress(avItem: AVPlayerItem) {
        //监听缓存进度，根据时间来监听
        let timeRange = avItem.loadedTimeRanges
        if timeRange.count > 0 {
            let cmTimeRange = timeRange[0] as! CMTimeRange
            let startSeconds = CMTimeGetSeconds(cmTimeRange.start)
            let durationSeconds = CMTimeGetSeconds(cmTimeRange.duration)
            let timeInterval = startSeconds + durationSeconds                    // 计算总进度
            self.loadedValue = Float(timeInterval)                               // 保存缓存
        }
    }
    private func updateTimeLableLayout(avItem: AVPlayerItem) {
        let duration = Float(avItem.asset.duration.value)/Float(avItem.asset.duration.timescale)
       // let currentTime =  avItem.currentTime().value/Int64(avItem.currentTime().timescale)
        videoDuration = Float(duration)
       // coverView.controlView.isUserInteractionEnabled = true
        /// 总时长小于最低时长，不能拖动进度
        coverView.panGesture.isEnabled = duration >= minTimeForDragProgress
        coverView.progressTapGesture.isEnabled = duration >= minTimeForDragProgress
        //print("video time length = \(duration) s, current time = \(currentTime) s")
    }
    private func updateTimeSliderValue(avItem: AVPlayerItem) {
        let timeScaleValue = Int64(avItem.currentTime().timescale) /// 当前时间
        let timeScaleDuration = Int64(avItem.asset.duration.timescale)   /// 总时间
        if avItem.asset.duration.value > 0 && avItem.currentTime().value > 0 {
            let value = avItem.currentTime().value / timeScaleValue  /// 当前播放时间
            let duration = avItem.asset.duration.value / timeScaleDuration /// 视频总时长
            let playValue = Float(value)/Float(duration)
            delegate?.playerProgress(progress: playValue, currentPlayTime: Float(value))
            if !coverView.draging {
                playedValue = Float(value)
                coverView?.progressView.setProgress(playValue, animated: false)
            }
        }
    }
}

// MARK: - Listen To the Player (监听播放狀態)
extension X_PlayerView {
    
    @objc func playToEnd(_ sender: Notification) {
        delegate?.currentUrlPlayToEnd(url: playUrl, player: self)
    }
    
    /// - Parameter sender: 记录被挂起前的播放狀態，进入前台时恢复狀態
    @objc func applicationResignActivity(_ sender: NSNotification) {
        if playerStatu != .Pause {
            playerStatu = .Pause
        }
    }
    
    @objc func applicationBecomeActivity(_ sender: NSNotification) {
        if let vc = self.getNextVC() {
            if vc.isViewLoaded && vc.view.window != nil {
                 playerStatu = .Playing
            }
        }
    }
    
    // 监听PlayerItem对象
    private func listenTothePlayer() {
        guard let item = avItem else { return }
        playerTimerObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: Int64(1.0), timescale: Int32(1.0)), queue: nil, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            strongSelf.updateTimeSliderValue(avItem: item)
            
        }) as? NSObject
    }
    func getNextVC() -> UIViewController? {
        var next = self.superview
        while (next != nil) {
            let nextResponder = next?.next
            if nextResponder?.isKind(of: UIViewController.self) ?? false {
                return nextResponder as? UIViewController
            }
            next = next?.superview
        }
        return nil
    }
    
}

// MARK: - PlayerCoverDelegate
extension X_PlayerView: PlayerCoverDelegate {
    
    func progressDraging(progress: Double) {
        let currenTime = Int(Double(videoDuration) * progress)
        let allTimeString = RXPublicConfig.formatTimDuration(duration: Int(videoDuration))
        let draggedTimeString = RXPublicConfig.formatTimPosition(position: currenTime, duration: Int(videoDuration))
        coverView.draggedTimeLable.text = String(format: " %@ | %@ ", draggedTimeString, allTimeString)
        delegate?.dragingProgress(isDraging: true, to: Float(progress))
    }

    func moveProgressIn(point: Double) {
        guard let item = avItem else { return }
        let position = CGFloat(item.asset.duration.value)/CGFloat(item.asset.duration.timescale)
        let po = CMTimeMakeWithSeconds(Float64(position) * Float64(point), preferredTimescale: (item.asset.duration.timescale))
        item.seek(to: po, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        playerStatu = .Playing
        coverView.startLoading()
        delegate?.dragingProgress(isDraging: false, to: Float(point))
    }
   
    func singleTapCoverView() {
        if playerStatu != .Pause {
            playerStatu = .Pause
        } else {
            playerStatu = .Playing
        }
    }
    
    func doubleTapCoverViewAt(point: CGPoint) {
        delegate?.doubleTapGestureAt(point: point)
    }
    
}

// MARK: - Layout
private extension X_PlayerView {
    func layoutPageSubviews() {
        layoutSelf()
        layoutCoverView()
        layoutPauseImg()
    }
    func layoutSelf() {
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    func layoutCoverView() {
        coverView?.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    func layoutPauseImg () {
        pauseImg.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(55)
        }
    }
}
