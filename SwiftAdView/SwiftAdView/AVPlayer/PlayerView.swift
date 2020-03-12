

import UIKit
import Foundation
import AVFoundation


public class PlayerView: UIView {
    
    enum PlayerStatus {
        case Failed
        case ReadyToPlay
        case Buffering
        case Playing
        case Pause
    }
    
    private var playerStatu: PlayerStatus? {
        didSet {
            if playerStatu == .Playing {
                player?.rate = 1.0
                player?.play()
                pauseImg.isHidden = true
            }else if playerStatu == .Pause {
                player?.rate = 0.0
                player?.pause()
                pauseImg.isHidden = false
            }
        }
    }
    /// 当前播放进度
    private var playedValue: Float = 0
    /// 加载进度
    private var loadedValue: Float = 0
    /// 视频总时长
    private var videoDuration: Float = 0
    
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var avItem: AVPlayerItem?
    private var avAsset: AVURLAsset?
    private var playerTimerObserver: NSObject?
    /// 暂停按钮
    private let pauseImg: UIImageView = {
        let image = UIImageView(image: UIImage(named: "pause"))
        image.isUserInteractionEnabled = true
        image.contentMode = .scaleAspectFit
        image.isHidden = true
        return image
    }()
    /// 播放控制View
    private  var coverView: PlayerCoverView!
    public weak var delegate: PlayerViewDelegate?
    public var playUrl: URL?
    /// 操作栏底部 相对父视图的 距离
    var controlViewBottomInset: CGFloat = 0
    /// 加载动画颜色
    var loadingBarColor: UIColor? = UIColor.white
    /// 进度条 颜色
    var progressTintColor: UIColor? = UIColor(white: 0.85, alpha: 0.9)
    var progressBackgroundColor: UIColor? = UIColor(white: 0.5, alpha: 0.1)
    var controlViewColor: UIColor? = UIColor.clear
    /// 进度条高度 (不能高于 controlViewHeight )
    var progressHeight: CGFloat = 0.5
    /// 拖动时的进度条高度
    var selectedProgrossHight: CGFloat = 6.0
    /// 底部操作栏高度（操作栏高度会影响 进度条拖动手势的响应面积 从而影响 灵敏度 ，越高越敏度）
    var controlViewHeight: CGFloat = 50.0
    /// The minimum time required to drag a progress bar (Unit: second)
    var minTimeForDragProgress: Float = 30.0
    
    deinit {
        print("播放器释放")
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
                updateTimeLableLayout(avItem: avItem)
                coverView.stopLoading()
                delegate?.readyToPlay()
            } else if avItem.status == .unknown || avItem.status == .failed {
                //视频加载失败，或者未知原因
                playerStatu = .Failed
                delegate?.playVideoFailed(url: playUrl, player: self)
            }
        } else if keyPath == "loadedTimeRanges" {
            updateLoadingProgress(avItem: avItem)
        } else if keyPath == "playbackBufferEmpty" {   // 监听播放器正在缓冲数据
            playerStatu = PlayerStatus.Buffering
            delegate?.loadingPlayResource()
        } else if keyPath == "playbackLikelyToKeepUp" {  //监听视频缓冲达到可以播放的狀態
            delegate?.startPlay()
        }
    }
    
    public func pause() {
        playerStatu = .Pause
    }
    public func play() {
        playerStatu = .Playing
    }
    public func replay() {
        avItem?.seek(to: CMTime.zero)
        coverView?.progressView.setProgress(0, animated: false)
        playerStatu = .Playing
    }
    public func stopPlaying() {
        realeasePlayer()
    }
    public func startPlay(url: URL?, in view: UIView) {
        
        guard let trueUrl = url else {
            delegate?.playVideoFailed(url: url, player: self)
            return
        }
        if view.subviews.contains(self) { return }
        realeasePlayer()
        playUrl = url
        if coverView != nil {
            coverView.removeFromSuperview()
        }
        avAsset = AVURLAsset(url: trueUrl, options: nil)
        avItem = AVPlayerItem(asset: avAsset!)
        player = AVPlayer(playerItem: avItem!)
        playerLayer = AVPlayerLayer(player: player!)
        playerLayer?.frame = self.bounds
        playerLayer?.videoGravity = .resizeAspect
        self.layer.addSublayer(playerLayer!)

        coverView = PlayerCoverView(config: loadConfig())
        coverView?.delegate = self
        
        view.addSubview(self)
        self.addSubview(coverView)
        self.addSubview(pauseImg)
        layoutPageSubviews()
        
        addPlayerObserver()
        
        player?.play()
        coverView.startLoading()
        listenTothePlayer()
        
    }
    
    private func loadConfig() -> PlayerViewConfig {
        let config = PlayerViewConfig()
        config.controlBarBottomInset = self.controlViewBottomInset
        config.controlViewColor = controlViewColor
        config.loadingBarColor = loadingBarColor
        config.progressBackgroundColor = progressBackgroundColor
        config.progressTintColor = progressTintColor
        config.progressHeight = progressHeight
        config.selectedProgrossHight = selectedProgrossHight
        config.controlViewHeight = controlViewHeight
        if progressHeight > controlViewHeight {
            config.controlViewHeight = progressHeight
        }
        return config
    }
    /// 销毁播放器源
    private func realeasePlayer() {
        avItem?.removeObserver(self, forKeyPath: "status")
        avItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        avItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        avItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        player?.rate = 0
        player?.cancelPendingPrerolls()
        avAsset = nil
        avItem = nil
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
        let currentTime =  avItem.currentTime().value/Int64(avItem.currentTime().timescale)
        self.videoDuration = Float(duration)
       
        /// 总时长小于最低时长，不能拖动进度
        coverView.panGesture.isEnabled = duration >= minTimeForDragProgress
        coverView.progressTapGesture.isEnabled = duration >= minTimeForDragProgress
        print("video time length = \(duration) s, current time = \(currentTime) s")
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
extension PlayerView {
    
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
        playerStatu = .Playing
    }
    
    // 监听PlayerItem对象
    private func listenTothePlayer() {
        guard let item = avItem else { return }
        playerTimerObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: Int64(1.0), timescale: Int32(1.0)), queue: nil, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            strongSelf.updateTimeSliderValue(avItem: item)
            
        }) as? NSObject
    }
    
}

// MARK: - PlayerCoverDelegate
extension PlayerView: PlayerCoverDelegate {
    
    func progressDraging(progress: Double) {
        let currenTime = Int(Double(videoDuration) * progress)
        let allTimeString =  formatTimDuration(position: Int(videoDuration), duration: Int(videoDuration))
        let draggedTimeString = formatTimPosition(position: currenTime, duration: Int(videoDuration))
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
            playerStatu = PlayerStatus.Pause
        } else {
            playerStatu = PlayerStatus.Playing
        }
    }
    
    func doubleTapCoverViewAt(point: CGPoint) {
        delegate?.doubleTapGestureAt(point: point)
    }
    
}

// MARK: - Layout
private extension PlayerView {
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
            make.width.height.equalTo(60)
        }
    }
}

extension PlayerView {
    
    fileprivate func formatTimPosition(position: Int, duration:Int) -> String {
        guard position != 0 && duration != 0 else{
            return "00:00"
        }
        let positionHours = (position / 3600) % 60
        let positionMinutes = (position / 60) % 60
        let positionSeconds = position % 60
        let durationHours = (Int(duration) / 3600) % 60
        if (durationHours == 0) {
            return String(format: "%02d:%02d",positionMinutes,positionSeconds)
        }
        return String(format: "%02d:%02d:%02d",positionHours,positionMinutes,positionSeconds)
    }
    
    fileprivate func formatTimDuration(position: Int, duration:Int) -> String {
        guard  duration != 0 else{
            return "00:00"
        }
        let durationHours = (duration / 3600) % 60
        let durationMinutes = (duration / 60) % 60
        let durationSeconds = duration % 60
        if (durationHours == 0)  {
            return String(format: "%02d:%02d",durationMinutes,durationSeconds)
        }
        return String(format: "%02d:%02d:%02d",durationHours,durationMinutes,durationSeconds)
    }
}
