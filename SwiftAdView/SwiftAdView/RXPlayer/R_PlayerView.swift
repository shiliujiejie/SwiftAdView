
import UIKit
import AVFoundation
import AVKit
import SnapKit
import MediaPlayer

public protocol RXCustomMuneDelegate: class {
    /// 自定义右上角按钮点击操作
    func showCustomMuneView() -> UIView?
    
    func customTopBarActions() -> [UIButton]?
}

public extension RXCustomMuneDelegate {
    
    func showCustomMuneView() -> UIView? {
        return nil
    }
    func customTopBarActions() -> [UIButton]? {
        return nil
    }
}

public protocol RXPlayerDelegate: class {
    
    /// 代理在外部处理网络问题
    func retryToPlayVideo(_ player: RXPlayerView, _ videoModel: RXVideoModel?, _ fatherView: UIView?)
    
    /// 当前播放的视频播放完成时调用
    ///
    /// - Parameters:
    ///   - videoModel: 当前播放完的本地视频的Model
    ///   - isPlayingDownLoadFile: 是否是播放的已下载视频
    func currentVideoPlayToEnd(_ videoModel: RXVideoModel?, _ isPlayingDownLoadFile: Bool)
}

public extension RXPlayerDelegate {
    func currentVideoPlayToEnd(_ videoModel: RXVideoModel?, _ isPlayingDownLoadFile: Bool) {
    }
}

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

/// 滑动手势的方向
enum PanDirection: Int {
    case PanDirectionHorizontal     //水平
    case PanDirectionVertical       //上下
}

/// 播放器View
open class RXPlayerView: UIView {
    
    static let kCustomViewTag = 6666
    
    // MARK: - ************** --> Public Var <-- **************
    /// 播放状态
    public var playerStatu: PlayerStatus? {
        didSet {
            if playerStatu == PlayerStatus.Playing {
                playControllViewEmbed.playOrPauseBtn.isSelected = true
                player?.play()
                player?.rate = 1.0
                if self.subviews.contains(pauseButton) {
                    pauseButton.isHidden = true
                    pauseButton.removeFromSuperview()
                }
            }else if playerStatu == PlayerStatus.Pause {
                player?.pause()
                player?.rate = 0
                hideLoadingHud()
                playControllViewEmbed.playOrPauseBtn.isSelected = false
                if !self.subviews.contains(pauseButton) {
                    self.insertSubview(pauseButton, aboveSubview: playControllViewEmbed)
                    pauseButton.isHidden = false
                    layoutPauseButton()
                }
            }
        }
    }
    /// 是否是全屏
    public var isFullScreen: Bool? = false {
        didSet {  // 监听全屏切换， 改变返回按钮，全屏按钮的状态和图片
            playControllViewEmbed.closeButton.isSelected = isFullScreen!
            playControllViewEmbed.fullScreen = isFullScreen!
            
//            if let view = UIApplication.shared.value(forKey: "statusBar") as? UIView {  // 状态栏变化
//                if !isFullScreen! {
//                    view.alpha = 1.0
//                } else {  // 全频
//                    if playControllViewEmbed.barIsHidden! { // 状态栏
//                        view.alpha = 0
//                    } else {
//                        view.alpha = 1.0
//                    }
//                }
//            }
            if !isFullScreen! {
                /// 非全屏状态下，移除自定义视图
                if let customView = self.viewWithTag(RXPlayerView.kCustomViewTag) {
                    customView.removeFromSuperview()
                }
                playControllViewEmbed.munesButton.isHidden = true
                playControllViewEmbed.closeButton.snp.updateConstraints { (make) in
                    make.width.equalTo(5)
                }
                playControllViewEmbed.closeButton.isEnabled = false
            }else {
                playControllViewEmbed.closeButton.snp.updateConstraints { (make) in
                    make.width.equalTo(40)
                }
                playControllViewEmbed.closeButton.isEnabled = true
                if customViewDelegate != nil {
                    if let actions = customViewDelegate!.customTopBarActions(), actions.count > 0 {  // 自定义了右上角操作按钮
                        playControllViewEmbed.munesButton.isHidden = true
                    } else {   // 没有自定义按钮，检查是否自定义覆盖层
                        if customViewDelegate!.showCustomMuneView() != nil { // 自定义覆盖层
                            playControllViewEmbed.munesButton.isHidden = false
                        } else {
                            playControllViewEmbed.munesButton.isHidden = true
                        }
                    }
                } else {
                    playControllViewEmbed.munesButton.isHidden = true
                }
            }
        }
    }
    /// 视频填充模式
    public var videoLayerGravity: AVLayerVideoGravity = .resizeAspect
    /// 是否只在全屏时显示视频名称
    public var videoNameShowOnlyFullScreen: Bool = false
    public weak var delegate: RXPlayerDelegate?
    public weak var customViewDelegate: RXCustomMuneDelegate?
    
    /// 本地视频播放时回调视频播放进度
    public var playLocalFileVideoCloseCallBack:((_ playValue: Float) -> Void)?
    
    
    // MARK: - ************** --> Private Var <-- **************
    private var sliderTouchBeginValue: Float64? = 0  // 记录进度条拖动前的值
    /// 视频截图
    private(set)  var imageGenerator: AVAssetImageGenerator?  // 用来做预览，目前没有预览的需求
    /// 当前屏幕状态
    private var currentOrientation: UIInterfaceOrientation?
    /// 保存传入的播放时间起点
    private var playTimeSince: Float = 0
    /// 当前播放进度
    private var playedValue: Float = 0 {  // 播放进度
        didSet {
            if oldValue < playedValue {  // 表示在播放中
                if !playControllViewEmbed.panGesture.isEnabled && !playControllViewEmbed.screenIsLock! {
                    playControllViewEmbed.panGesture.isEnabled = true
                }
                self.hideLoadingHud()
                if self.subviews.contains(loadedFailedView) {
                    self.loadedFailedView.removeFromSuperview()
                }
            }
        }
    }
    /// 父视图
    private weak var fatherView: UIView?  {
        didSet {
            if fatherView != nil && !(fatherView?.subviews.contains(self))! {
                fatherView?.addSubview(self)
            }
        }
    }
    /// 嵌入式播放控制View
    private lazy var playControllViewEmbed: RXPlayerControlView = {
        let playControllView = RXPlayerControlView(frame: self.bounds)
        playControllView.delegate = self
        return playControllView
    }()
    /// 显示拖动进度的显示
    private lazy var draggedProgressView: UIView = {
        let view = UIView()
        view.backgroundColor =  UIColor.clear
        view.addSubview(self.draggedStatusButton)
        view.addSubview(self.draggedTimeLable)
        view.layer.cornerRadius = 3
        return view
    }()
    private let draggedStatusButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(RXImgManager.foundImage(imageName: "forward"), for: .normal)
        button.setImage(RXImgManager.foundImage(imageName: "backward"), for: .selected)
        button.isUserInteractionEnabled = false
        return button
    }()
    private let draggedTimeLable: UILabel = {
        let lable = UILabel()
        lable.textColor = UIColor.white
        lable.font = UIFont.systemFont(ofSize: 13)
        lable.textAlignment = .center
        return lable
    }()
    /// 暂停按钮
    private lazy var pauseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(RXImgManager.foundImage(imageName: "pause"), for: .normal)
        button.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        button.imageEdgeInsets.left = 5
        button.layer.cornerRadius = 27.5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(pauseButtonClick), for: .touchUpInside)
        return button
    }()
    /// 网络不好时提示
    private lazy var loadedFailedView: RXLoadedFailedView = {
        let failedView = RXLoadedFailedView(frame: self.bounds)
        failedView.backgroundColor = UIColor(white: 0.2, alpha: 0.5)
        return failedView
    }()
    
    /// 网络视频链接(每次对链接赋值，都会重置播放器)
    private var playUrl: URL? {
        didSet {
            if let videoUrl = playUrl {
                resetPlayerResource(videoUrl)
            }
        }
    }
    /// 本地视频链接
    private var fileUrlString: String?
    /// 视频名称
    private var videoName: String? {
        didSet {
            if videoName != nil {
                playControllViewEmbed.videoNameLable.text = String(format: "%@", videoName!)
            }
        }
    }
    /// 亮度显示
    private var brightnessSlider: RXBrightnessView = {
        let brightView = RXBrightnessView(frame: CGRect(x: 0, y: 0, width: 155, height: 155))
        return brightView
    }()
    private lazy var volumeView: MPVolumeView = {
        let volumeV = MPVolumeView()
        volumeV.showsVolumeSlider = false
        volumeV.showsRouteButton = false
        volumeSlider = nil //每次获取要将之前的置为nil
        for view in volumeV.subviews {
            if view.classForCoder.description() == "MPVolumeSlider" {
                if let vSlider = view as? UISlider {
                    volumeSlider = vSlider
                    volumeSliderValue = Float64(vSlider.value)
                }
                break
            }
        }
        return volumeV
    }()
    /// 进入后台前的屏幕状态
    private var beforeEnterBackgoundOrientation: UIInterfaceOrientation?   // 暂时没用到
    /// 滑动手势的方向
    private var panDirection: PanDirection?
    /// 记录拖动的值
    private var sumTime: CGFloat?
    /// 进度条滑动之前的播放状态，保证滑动进度后，恢复到滑动之前的播放状态
    private var beforeSliderChangePlayStatu: PlayerStatus?
    /// 加载进度
    private var loadedValue: Float = 0
    /// 视频总时长
    private var videoDuration: Float = 0
    /// 是否为.m3u8格式
    private var isM3U8: Bool = false
    /// 是否正在拖动进度
    private var isDragging: Bool = false
    /// 音量大小
    private var volumeSliderValue: Float64 = 0
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var avItem: AVPlayerItem?
    private var playerTimerObserver: NSObject?
    private var resouerLoader: RXAssetResourceLoader?
    /// 音量显示
    private var volumeSlider: UISlider?
    
    // MARK: - Life - Cycle
    
    deinit {
        print("播放器释放")
        NotificationCenter.default.removeObserver(self)
        avItem?.removeObserver(self, forKeyPath: "status")
        avItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        avItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        avItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        orientationSupport = RXPlayerOrietation.orientationPortrait
        destructPlayerResource()
    }
    
    /// 构造方法
    ///
    /// - Parameters:
    ///   - frame: 坐标，可以不设置
    ///   - bottomBarBothSide: 选择底部操作栏的样式
    public init(frame: CGRect, bothSidesTimelable: Bool? = true) {
        super.init(frame: frame)
        self.backgroundColor = .black
        // 注册APP被挂起 + 进入前台通知
        NotificationCenter.default.addObserver(self, selector: #selector(RXPlayerView.applicationResignActivity(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RXPlayerView.applicationBecomeActivity(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - Open Func (api)

extension RXPlayerView {
    
    /// 播放视频
    ///
    /// - Parameters:
    ///   - videoUrl: 视频链接
    ///   - videoName: 视频名称（非必传）
    ///   - containerView: 视频父视图
    open func playVideo(_ videoUrl: URL?, _ videoName: String? = nil, _ containerView: UIView?) {
        // 这里有个视频解密过程
        playVideoWith(videoUrl, videoName: videoName, containView: containerView)
    }
    
    ///   从某个时间点开始播放视频
    ///
    /// - Parameters:
    ///   - videoUrl: 视频连接
    ///   - videoTitle: 视屏名称
    ///   - containerView: 视频父视图
    ///   - lastPlayTime: 上次播放的时间点
    open func replayVideo(_ videoUrl: URL?, _ videoTitle: String? = nil, _ containerView: UIView?, _ lastPlayTime: Float) {
        self.playVideo(videoUrl, videoTitle, containerView)
        guard let avItem = self.avItem else { return }
        self.playTimeSince = lastPlayTime              // 保存播放起点，在网络断开时，点击重试，可以找到起点
        hideLoadingHud()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let lastPositionValue = CMTimeMakeWithSeconds(Float64(lastPlayTime), preferredTimescale: (avItem.asset.duration.timescale))
            self.playSinceTime(lastPositionValue)
        }
    }
   
    /// 直接全屏播放，思路就是：直接将播放器添加到父视图上，：1.播放视频，2：屏幕强制旋转到右侧，3.隐藏全屏切换按钮 ，4.更换返回按钮事件为移除播放器
    ///
    /// - Parameters:
    ///   - videoUrl: 视屏URL
    ///   - videoTitle: 视屏名称
    ///   - containerView: 父视图
    ///   - sinceTime: 从某个时间点开始播放
    open func playVideoInFullscreen(_ url: String?, _ videoTitle: String? = nil, _ containerView: UIView?, sinceTime: Float? = nil) {
        playDownFileWith(url, videoTitle, containerView, sinceTime: sinceTime)
    }
    
    /// 改变播放器的父视图
    ///
    /// - Parameter containerView: New fatherView
    open func changeVideoContainerView(_ containerView: UIView) {
        if fatherView != containerView {
            fatherView = containerView
            layoutAllPageSubviews()        //改变了父视图，需要重新布局
        }
    }
    
    /// 获取当前播放时间点 + 视频总时长
    ///
    /// - Returns: 返回当前视频播放的时间,和视频总时长 （单位: 秒）
    open func getNowPlayPositionTimeAndVideoDuration() -> [Float] {
        return [self.playedValue, self.videoDuration]
    }
    
    /// 获取当前已缓存的时间点
    ///
    /// - Returns: 返回当前已缓存的时间 （单位: 秒）
    open func getLoadingPositionTime() -> Float {
        return self.loadedValue
    }
    /// 设置播放速度： effective range [0.5 - 2.0]
    open func resetRate(rate: Float) {
        if rate < 0.5 || rate > 2.0 { return }
        if player?.rate == rate { return }
        player?.rate = rate
    }
    /// 取消视频缓存加载
    open func cancle() {
        resouerLoader?.cancel()
    }
    
    open func destroyPlayer() {
        releasePlayer()
        self.removeFromSuperview()
    }
    
    /// 强制横屏
    ///
    /// - Parameter orientation: 通过KVC直接设置屏幕旋转方向
    open func interfaceOrientation(_ orientation: UIInterfaceOrientation) {
        if orientation == UIInterfaceOrientation.landscapeRight || orientation == UIInterfaceOrientation.landscapeLeft {
            UIDevice.current.setValue(NSNumber(integerLiteral: UIInterfaceOrientation.landscapeRight.rawValue), forKey: "orientation")
        }else if orientation == UIInterfaceOrientation.portrait {
            UIDevice.current.setValue(NSNumber(integerLiteral: UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
        }
    }
    
    /// 移除当前播放器屏幕方向监听
    open func disableDeviceOrientationChange() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
    }
    
    /// 注册屏幕旋转监听通知
    open func enableDeviceOrientationChange() {
        NotificationCenter.default.addObserver(self, selector: #selector(RXPlayerView.orientChange(_:)), name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
    }
    
}

// MARK: - Private Funcs (私有方法)

private extension RXPlayerView {
    
    private func playVideoWith(_ url: URL?, videoName: String?, containView: UIView?) {
        // 👇三个属性的设置顺序很重要
        self.playUrl = url   // 判断视频链接是否更改，更改了就重置播放器
        self.videoName = videoName      // 视频名称
        self.playControllViewEmbed.videoNameLable.isHidden = videoNameShowOnlyFullScreen
        
        if !isFullScreen! {
            fatherView = containView // 更换父视图时
        }
        layoutAllPageSubviews()
        
        addNotificationAndObserver()
        addUserActionBlock()
        if customViewDelegate != nil {
            if let actions = customViewDelegate!.customTopBarActions(), actions.count > 0 {  // 自定义了右上角操作按钮
                showCustomTopBarActions(actions: actions)
            }
        }
    }
    
    /// 播放本地视频文件 : 1.标注为播放本地文件。 2.初始化播放器，播放视频）。 3.根据标记改变屏幕支持方向。4.隐藏全屏按钮 5.强制横屏
    ///
    /// - Parameters:
    ///   - filePathUrl: 本地连接
    ///   - videoTitle: 视频名称
    ///   - containerView: 父视图
    ///   - sinceTime: 从某个时间开始播放
    
    private func playDownFileWith(_ filePathUrl: String?, _ videoTitle: String?, _ containerView: UIView?, sinceTime: Float? = nil) {
        guard let localUrl = filePathUrl else { return }
        playControllViewEmbed.playLocalFile = true  // 声明直接就进入全屏播放               ------------------   1
        fileUrlString = localUrl              // 保存本地文件URL
        /// 重置播放源
        /// 这里这样写，是为了兼容，ts流 本地服务器播放， m3u8视频 文件 ts 下载后，需要搭建本地服务器播放，走的也是网络播放，只是资源在本地，通过
        var url: URL!
        if localUrl.hasPrefix("http") {
            url = URL(string: localUrl)
        } else {
            url = URL(fileURLWithPath: localUrl)
        }
        // 👇三个属性的设置顺序很重要X
        self.playUrl = url                // 判断视频链接是否更改，更改了就重置播放器        // ------------------------- 2  + 3
        self.videoName = videoTitle      // 视频名称
        if !isFullScreen! {
            fatherView = containerView // 更换父视图时
        }
        playControllViewEmbed.loadedProgressView.setProgress(1, animated: false)
        self.playControllViewEmbed.fullScreenBtn.isHidden = true                      // --------------------------- 4
        layoutAllPageSubviews()
        addNotificationAndObserver()
        addUserActionBlock()
        playControllViewEmbed.closeButton.setImage(RXImgManager.foundImage(imageName: "back"), for: .normal)
        playControllViewEmbed.closeButton.snp.updateConstraints({ (make) in
            make.width.equalTo(40)
        })
        interfaceOrientation(UIInterfaceOrientation.portrait)           // 为了避免在横屏状态下点击播放，强制横屏不走，先强制竖屏，在强制横屏
        interfaceOrientation(UIInterfaceOrientation.landscapeRight)                       // ---------------------------- 5
        /// 播放记录
        if let playLastTime = sinceTime, playLastTime > 1 {
            self.playTimeSince = playLastTime      // 保存播放起点，在网络断开时，点击重试，可以找到起点
            guard let avItem = self.avItem else{return}
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let lastPositionValue = CMTimeMakeWithSeconds(Float64(playLastTime), preferredTimescale: (avItem.asset.duration.timescale))
                self.playSinceTime(lastPositionValue)
            }
        }
        if customViewDelegate != nil {
            if let actions = customViewDelegate!.customTopBarActions(), actions.count > 0 {  // 自定义了右上角操作按钮
                showCustomTopBarActions(actions: actions)
            }
        }
        
    }
    
    private func showLoadingHud() {
        if !playControllViewEmbed.loadingView.isAnimating {
            playControllViewEmbed.loadingView.startAnimating()
        }
    }
    
    private func hideLoadingHud() {
        if playControllViewEmbed.loadingView.isAnimating {
            playControllViewEmbed.loadingView.stopAnimating()
        }
    }
    
    private func showCustomTopBarActions(actions: [UIButton]) {
        let count = actions.count > 4 ? 4 : actions.count
        for  i in 0 ..< count {
            let button = actions[i]
            playControllViewEmbed.topControlBarView.addSubview(button)
            button.snp.makeConstraints { (make) in
                make.top.equalTo(playControllViewEmbed.videoNameLable).offset(5)
                make.bottom.equalTo(playControllViewEmbed.videoNameLable)
                make.trailing.equalTo(-(20 + i*55))
                make.width.equalTo(40)
            }
        }
    }
    
    /// 释放播放源
    private func releasePlayer() {
        avItem?.removeObserver(self, forKeyPath: "status")
        avItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        avItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        avItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        if playerTimerObserver != nil {
            player?.removeTimeObserver(playerTimerObserver!)
            playerTimerObserver = nil
        }
        self.playerLayer?.removeFromSuperlayer()
        self.layer.removeAllAnimations()
        // player?.replaceCurrentItem(with: nil)
        avItem = nil
    }
    
    /// 初始化播放源
    ///
    /// - Parameter videoUrl: 视频链接
    private func setUpPlayerResource(_ videoUrl: URL) {
        
        if videoUrl.absoluteString.contains(".m3u8") {
            isM3U8 = true
            avItem = AVPlayerItem(asset: AVURLAsset(url: videoUrl, options: nil))
        } else {
            isM3U8 = false
            avItem = AVPlayerItem(asset: AVURLAsset(url: videoUrl, options: nil))
            //                resouerLoader = RXAssetResourceLoader()
            //                resouerLoader!.delegate = self
            //                let playUrl = resouerLoader!.getURL(url: videoUrl)
            //                avAsset = AVURLAsset(url: playUrl ?? videoUrl, options: nil)
            //                avAsset?.resourceLoader.setDelegate(resouerLoader, queue: DispatchQueue.main)
        }
        player = AVPlayer(playerItem: self.avItem!)
        playerLayer = AVPlayerLayer(player: self.player!)
        playerLayer?.videoGravity = videoLayerGravity
        self.layer.addSublayer(playerLayer!)
        self.addSubview(playControllViewEmbed)
        
        playControllViewEmbed.timeSlider.value = 0
        playControllViewEmbed.loadedProgressView.setProgress(0, animated: false)
        playControllViewEmbed.timeSlider.isEnabled = true //!isM3U8
        playControllViewEmbed.doubleTapGesture.isEnabled = true
        playControllViewEmbed.panGesture.isEnabled = true //!isM3U8
        autoHideBar()
        if playControllViewEmbed.playLocalFile! {       // 播放本地视频时只支持左右
            orientationSupport = RXPlayerOrietation.orientationLeftAndRight
        } else {
            showLoadingHud()      /// 网络视频才显示菊花
            orientationSupport = RXPlayerOrietation.orientationAll
        }
    }
    
    /// 重置播放器
    ///
    /// - Parameter videoUrl: 视频链接
    private func resetPlayerResource(_ videoUrl: URL) {
        
        releasePlayer()  // 先释放播放源
        startReadyToPlay()
        
        setUpPlayerResource(videoUrl)
    }
    
    /// 销毁播放器源
    private func destructPlayerResource() {
        self.avItem = nil
        self.player?.replaceCurrentItem(with: nil)
        self.player = nil
        self.playerLayer?.removeFromSuperlayer()
        self.layer.removeAllAnimations()
    }
    
    /// 从某个点开始播放
    ///
    /// - Parameter time: 要从开始的播放起点
    private func playSinceTime(_ time: CMTime) {
        if CMTIME_IS_VALID(time) {
            avItem?.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { [weak self] (finish) in
                if finish {
                    self?.hideLoadingHud()
                }
            })
            return
        }else {
            self.hideLoadingHud()
        }
    }
    
    /// 获取系统音量控件 及大小
    private func configureSystemVolume() {
        let volumeView = MPVolumeView()
        self.volumeSlider = nil //每次获取要将之前的置为nil
        for view in volumeView.subviews {
            if view.classForCoder.description() == "MPVolumeSlider" {
                if let vSlider = view as? UISlider {
                    volumeSlider = vSlider
                    volumeSliderValue = Float64(vSlider.value)
                }
                break
            }
        }
    }
    
    // MARK: - addNotificationAndObserver
    private func addNotificationAndObserver() {
        guard let avItem = self.avItem else {return}
        ///注册通知之前，需要先移除对应的通知，因为添加多此观察，方法会调用多次
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playToEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avItem)
        avItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        avItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        avItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
        avItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        // 注册屏幕旋转通知
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
        NotificationCenter.default.addObserver(self, selector: #selector(RXPlayerView.orientChange(_:)), name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
    }
    
    // MARK: - 返回，关闭，全屏，播放，暂停,重播,音量，亮度，进度拖动 - UserAction
    @objc func pauseButtonClick() {
        self.playerStatu = PlayerStatus.Playing
    }
    
    // MARK: - User Action - Block
    private func addUserActionBlock() {
        // MARK: - 返回，关闭
        playControllViewEmbed.closeButtonClickBlock = { [weak self] (sender) in
            guard let strongSelf = self else {return}
            if strongSelf.isFullScreen! {
                if strongSelf.playControllViewEmbed.playLocalFile! {   // 直接全屏播放本地视频
                    strongSelf.removeFromSuperview()
                    strongSelf.cancleAutoHideBar()
                    orientationSupport = RXPlayerOrietation.orientationPortrait
                    strongSelf.playLocalFileVideoCloseCallBack?(self?.playedValue ?? 0.0)
                    strongSelf.interfaceOrientation(UIInterfaceOrientation.landscapeRight)
                    strongSelf.interfaceOrientation(UIInterfaceOrientation.portrait)
                    
                } else {
                    strongSelf.interfaceOrientation(UIInterfaceOrientation.portrait)
                }
            }else {                                                    // 非全屏状态，停止播放，移除播放视图
                NLog("非全屏状态，停止播放，移除播放视图")
            }
        }
        // MARK: - 全屏
        playControllViewEmbed.fullScreenButtonClickBlock = { [weak self] (sender) in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.isFullScreen! {
                strongSelf.interfaceOrientation(UIInterfaceOrientation.portrait)
            }else{
                strongSelf.interfaceOrientation(UIInterfaceOrientation.landscapeRight)
            }
        }
        // MARK: - 播放暂停
        playControllViewEmbed.playOrPauseButtonClickBlock = { [weak self] (sender) in
            if self?.playerStatu == PlayerStatus.Playing || self?.playerStatu == PlayerStatus.Buffering || self?.playerStatu == PlayerStatus.ReadyToPlay {
                NLog("playerStatu = \(String(describing: self?.playerStatu))")
                self?.hideLoadingHud()
                self?.playerStatu = PlayerStatus.Pause
            } else if self?.playerStatu == PlayerStatus.Pause {
                self?.playerStatu = PlayerStatus.Playing
            }
        }
        // MARK: - 锁屏
        playControllViewEmbed.screenLockButtonClickBlock = { [weak self] (sender) in
            guard let strongSelf = self else { return }
            if sender.isSelected {
                orientationSupport = RXPlayerOrietation.orientationLeftAndRight
            }else {
                if strongSelf.playControllViewEmbed.playLocalFile! {
                    orientationSupport = RXPlayerOrietation.orientationLeftAndRight
                } else {
                    orientationSupport = RXPlayerOrietation.orientationAll
                }
            }
        }
        // MARK: - 重播
        playControllViewEmbed.replayButtonClickBlock = { [weak self] (_) in
            self?.avItem?.seek(to: .zero)
            self?.playControllViewEmbed.timeSlider.value = 0
            self?.playControllViewEmbed.screenIsLock = false
            self?.startReadyToPlay()
            self?.playerStatu = PlayerStatus.Playing
        }
        // MARK: - 分享按钮点击
        playControllViewEmbed.muneButtonClickBlock = { [weak self] (_) in
            guard let strongSelf = self else {
                return
            }
            /// 通过代理回调设置自定义覆盖操作视图
            if let customMuneView = strongSelf.customViewDelegate?.showCustomMuneView() {
                
                customMuneView.tag = RXPlayerView.kCustomViewTag /// 给外来视图打标签，便于移除
                
                if !strongSelf.subviews.contains(customMuneView) {
                    strongSelf.addSubview(customMuneView)
                }
                customMuneView.snp.makeConstraints({ (make) in
                    make.edges.equalToSuperview()
                })
            }
            
        }
        // MARK: - 音量，亮度，进度拖动
        self.configureSystemVolume()             // 获取系统音量控件   可以选择自定义，效果会比系统的好
        
        playControllViewEmbed.pangeustureAction = { [weak self] (sender) in
            guard let avItem = self?.avItem  else {return}                     // 如果 avItem 不存在，手势无响应
            guard let strongSelf = self else {return}
            let locationPoint = sender.location(in: strongSelf.playControllViewEmbed)
            /// 根据上次和本次移动的位置，算出一个速率的point
            let veloctyPoint = sender.velocity(in: strongSelf.playControllViewEmbed)
            switch sender.state {
            case .began:
                
                strongSelf.cancleAutoHideBar()
                strongSelf.playControllViewEmbed.barIsHidden = false
                strongSelf.isDragging = true
                // 使用绝对值来判断移动的方向
                let x = abs(veloctyPoint.x)
                let y = abs(veloctyPoint.y)
                
                if x > y {                       //水平滑动
                    
                    if !strongSelf.playControllViewEmbed.replayContainerView.isHidden {  // 锁屏状态下播放完成,解锁后，滑动
                        strongSelf.startReadyToPlay()
                        strongSelf.playControllViewEmbed.screenIsLock = false
                    }
                    strongSelf.panDirection = PanDirection.PanDirectionHorizontal
                    // strongSelf.beforeSliderChangePlayStatu = strongSelf.playerStatu  // 拖动开始时，记录下拖动前的状态
                    strongSelf.playerStatu = PlayerStatus.Pause
                    strongSelf.pauseButton.isHidden = true                     // 拖动时隐藏暂停按钮
                    strongSelf.sumTime = CGFloat(avItem.currentTime().value)/CGFloat(avItem.currentTime().timescale)
                    if !strongSelf.subviews.contains(strongSelf.draggedProgressView) {
                        strongSelf.addSubview(strongSelf.draggedProgressView)
                        strongSelf.layoutDraggedContainers()
                    }
                    
                }else if x < y {
                    strongSelf.panDirection = PanDirection.PanDirectionVertical
                    
                    if locationPoint.x > strongSelf.playControllViewEmbed.bounds.size.width/2 && locationPoint.y < strongSelf.playControllViewEmbed.bounds.size.height - 40 {  // 触摸点在视图右边，控制音量
                        // 如果需要自定义 音量控制显示，在这里添加自定义VIEW
                        if !strongSelf.subviews.contains(strongSelf.volumeView) {
                            strongSelf.addSubview(strongSelf.volumeView)
                            strongSelf.volumeView.snp.makeConstraints({ (make) in
                                make.center.equalToSuperview()
                                make.width.equalTo(155)
                                make.height.equalTo(155)
                            })
                        }
                        
                        
                    }else if locationPoint.x < strongSelf.playControllViewEmbed.bounds.size.width/2 && locationPoint.y < strongSelf.playControllViewEmbed.bounds.size.height - 40 {
                        if !strongSelf.subviews.contains(strongSelf.brightnessSlider) {
                            strongSelf.addSubview(strongSelf.brightnessSlider)
                            strongSelf.brightnessSlider.snp.makeConstraints({ (make) in
                                make.center.equalToSuperview()
                                make.width.equalTo(155)
                                make.height.equalTo(155)
                            })
                        }
                    }
                }
                break
            case .changed:
                switch strongSelf.panDirection! {
                case .PanDirectionHorizontal:
                    
                    let _ = strongSelf.horizontalMoved(veloctyPoint.x)
                    
                case .PanDirectionVertical:
                    if locationPoint.x > strongSelf.playControllViewEmbed.bounds.size.width/2 && locationPoint.y < strongSelf.playControllViewEmbed.bounds.size.height - 40 {
                        strongSelf.veloctyMoved(veloctyPoint.y, true)
                    }else if locationPoint.x < strongSelf.playControllViewEmbed.bounds.size.width/2 && locationPoint.y < strongSelf.playControllViewEmbed.bounds.size.height - 40 {
                        strongSelf.veloctyMoved(veloctyPoint.y, false)
                    }
                    break
                }
                break
            case .ended:
                strongSelf.isDragging = false
                switch strongSelf.panDirection! {
                case .PanDirectionHorizontal:
                    
                    let position = CGFloat(avItem.asset.duration.value)/CGFloat(avItem.asset.duration.timescale)
                    let sliderValue = strongSelf.sumTime!/position
                    let po = CMTimeMakeWithSeconds(Float64(position) * Float64(sliderValue), preferredTimescale: (avItem.asset.duration.timescale))
                    avItem.seek(to: po, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                    /// 拖动完成，sumTime置为0 回到之前的播放状态，如果播放状态为
                    strongSelf.sumTime = 0
                    strongSelf.pauseButton.isHidden = false
                    
                    strongSelf.playerStatu = PlayerStatus.Playing
                    //进度拖拽完成，5庙后自动隐藏操作栏
                    strongSelf.autoHideBar()
                    
                    if strongSelf.subviews.contains(strongSelf.draggedProgressView) {
                        strongSelf.draggedProgressView.removeFromSuperview()
                    }
                    break
                case .PanDirectionVertical:
                    //进度拖拽完成，5庙后自动隐藏操作栏
                    strongSelf.autoHideBar()
                    if locationPoint.x < strongSelf.playControllViewEmbed.bounds.size.width/2 {    // 触摸点在视图左边 隐藏屏幕亮度
                        strongSelf.brightnessSlider.removeFromSuperview()
                    } else {
                        strongSelf.volumeView.removeFromSuperview()
                    }
                    break
                }
                break
                
            case .possible:
                break
            case .failed:
                break
            case .cancelled:
                break
            }
        }
    }
    
    // MARK: - 水平拖动进度手势
    private func horizontalMoved(_ moveValue: CGFloat) ->CGFloat {
        guard var sumValue = self.sumTime else {
            return 0
        }
        // 限定sumTime的范围
        guard let avItem = self.avItem else {
            return 0
        }
        // 这里可以调整拖动灵敏度， 数字（99）越大，灵敏度越低
        sumValue += moveValue / 99
        
        let totalMoveDuration = CGFloat(avItem.asset.duration.value)/CGFloat(avItem.asset.duration.timescale)
        
        if sumValue > totalMoveDuration {
            sumValue = totalMoveDuration
        }
        if sumValue < 0 {
            sumValue = 0
        }
        let dragValue = sumValue / totalMoveDuration
        // 拖动时间展示
        let allTimeString =  formatTimDuration(position: Int(sumValue), duration: Int(totalMoveDuration))
        let draggedTimeString = formatTimPosition(position: Int(sumValue), duration: Int(totalMoveDuration))
        draggedTimeLable.text = String(format: "%@|%@", draggedTimeString, allTimeString)
        playControllViewEmbed.positionTimeLab.text = self.formatTimPosition(position: Int(sumValue), duration: Int(totalMoveDuration))
        draggedStatusButton.isSelected = moveValue < 0
        if !isDragging {
            playControllViewEmbed.timeSlider.value = Float(dragValue)
        }
        sumTime = sumValue
        return dragValue
        
    }
    
    // MARK: - 上下拖动手势
    private func veloctyMoved(_ movedValue: CGFloat, _ isVolume: Bool) {
        
        if isVolume {
            volumeSlider?.value  -= Float(movedValue/10000)
            
        }else {
            UIScreen.main.brightness  -= movedValue/10000
            self.brightnessSlider.updateBrightness(UIScreen.main.brightness)
        }
    }
    
    // MARK: - 播放结束
    /// 播放结束时调用
    ///
    /// - Parameter sender: 监听播放结束
    @objc func playToEnd(_ sender: Notification) {
        self.playerStatu = PlayerStatus.Pause //同时为暂停状态
        self.pauseButton.isHidden = true
        cancleAutoHideBar()               // 取消自动隐藏操作栏
        playControllViewEmbed.screenIsLock = false
        playControllViewEmbed.replayContainerView.isHidden = false
        playControllViewEmbed.barIsHidden = true
        playControllViewEmbed.singleTapGesture.isEnabled = true
        playControllViewEmbed.doubleTapGesture.isEnabled = false
        playControllViewEmbed.panGesture.isEnabled = false
        playControllViewEmbed.screenLockButton.isHidden = true
        playControllViewEmbed.loadedProgressView.setProgress(0, animated: false)
        hideLoadingHud()
        
        if let item = sender.object as? AVPlayerItem {   /// 这里要区分结束的视频是哪一个
            if let asset = item.asset as? AVURLAsset {
                let model = RXVideoModel(videoName: self.videoName, videoUrl: asset.url.absoluteString, videoPlaySinceTime: self.playTimeSince)
                delegate?.currentVideoPlayToEnd(model, playControllViewEmbed.playLocalFile!)
            }
        }
    }
    
    // MARK: - 开始播放准备
    private func startReadyToPlay() {
        playControllViewEmbed.barIsHidden = false
        playControllViewEmbed.replayContainerView.isHidden = true
        playControllViewEmbed.singleTapGesture.isEnabled = true
        playControllViewEmbed.positionTimeLab.text = "00:00"
        playControllViewEmbed.durationTimeLab.text = "00:00"
        loadedFailedView.removeFromSuperview()
    }
    
    // MARK: - 网络提示显示
    private func showLoadedFailedView() {
        self.addSubview(loadedFailedView)
        loadedFailedView.retryButtonClickBlock = { [weak self] (sender) in
            guard let strongSelf = self else { return }
            let model = RXVideoModel(videoName: strongSelf.videoName, videoUrl: strongSelf.playUrl?.absoluteString, videoPlaySinceTime: strongSelf.playTimeSince)
            //strongSelf.delegate?.retryToPlayVideo(strongSelf, model, strongSelf.fatherView)
            strongSelf.delegate?.retryToPlayVideo(strongSelf, model, strongSelf.fatherView)
        }
        loadedFailedView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - 取消自动隐藏操作栏
    private func cancleAutoHideBar() {
        NSObject.cancelPreviousPerformRequests(withTarget: playControllViewEmbed, selector: #selector(RXPlayerControlView.autoHideTopBottomBar), object: nil)    // 取消5秒自动消失控制栏
    }
    
    // MARK: - 添加操作栏5秒自动隐藏
    private func autoHideBar() {
        // 取消5秒自动消失控制栏
        NSObject.cancelPreviousPerformRequests(withTarget: playControllViewEmbed, selector: #selector(RXPlayerControlView.autoHideTopBottomBar), object: nil)
        playControllViewEmbed.perform(#selector(RXPlayerControlView.autoHideTopBottomBar), with: nil, afterDelay: 5)
    }
    
    // MARK: - InterfaceOrientation - Change (屏幕方向改变)
    @objc func orientChange(_ sender: Notification) {
        let orirntation = UIApplication.shared.statusBarOrientation
        if  orirntation == UIInterfaceOrientation.landscapeLeft || orirntation == UIInterfaceOrientation.landscapeRight  {
            isFullScreen = true
            self.removeFromSuperview()
            UIApplication.shared.keyWindow?.addSubview(self)
            UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.transitionCurlUp, animations: {
                self.snp.makeConstraints({ (make) in
                    make.edges.equalTo(UIApplication.shared.keyWindow!)
                })
                self.layoutIfNeeded()
                self.playControllViewEmbed.layoutIfNeeded()
                self.playControllViewEmbed.videoNameLable.isHidden = false
            }, completion: nil)
            
        } else if orirntation == UIInterfaceOrientation.portrait {
            if !self.playControllViewEmbed.screenIsLock! { // 非锁品状态下
                isFullScreen = false
                self.removeFromSuperview()
                if let containerView = self.fatherView {
                    containerView.addSubview(self)
                    UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
                        self.snp.makeConstraints({ (make) in
                            make.edges.equalTo(containerView)
                        })
                        self.layoutIfNeeded()
                        self.playControllViewEmbed.layoutIfNeeded()
                        self.playControllViewEmbed.videoNameLable.isHidden = self.videoNameShowOnlyFullScreen
                    }, completion: nil)
                }
            }
        }
    }
    
    // MARK: - APP将要被挂起
    /// - Parameter sender: 记录被挂起前的播放状态，进入前台时恢复状态
    @objc func applicationResignActivity(_ sender: NSNotification) {
        self.beforeSliderChangePlayStatu = self.playerStatu  // 记录下进入后台前的播放状态
        if playerStatu == PlayerStatus.Playing {
            playerStatu = PlayerStatus.Pause
        }
    }
    
    // MARK: - APP进入前台，恢复播放状态
    @objc func applicationBecomeActivity(_ sender: NSNotification) {
        if let oldStatu = self.beforeSliderChangePlayStatu {
            self.playerStatu = oldStatu                      // 恢复进入后台前的播放状态
        }
    }
    
}

// MARK: - RXPlayerControlViewDelegate
extension RXPlayerView: RXPlayerControlViewDelegate {
    
    func sliderTouchBegin(_ sender: UISlider) {
        guard let avItem = self.avItem else { return }
        //beforeSliderChangePlayStatu = playerStatu、
        playerStatu = PlayerStatus.Pause
        isDragging = true
        playControllViewEmbed.replayContainerView.isHidden = true
        pauseButton.isHidden = true
        let duration = Float64 ((avItem.asset.duration.value)/Int64(avItem.asset.duration.timescale))
        sliderTouchBeginValue = Float64(duration) * Float64(sender.value)
    }
    
    func sliderTouchEnd(_ sender: UISlider) {
        guard let avItem = self.avItem else {
            return
        }
        let position = Float64 ((avItem.asset.duration.value)/Int64(avItem.asset.duration.timescale))
        let po = CMTimeMakeWithSeconds(Float64(position) * Float64(sender.value), preferredTimescale: (avItem.asset.duration.timescale))
        avItem.seek(to: po, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        pauseButton.isHidden = false
        playerStatu = PlayerStatus.Playing
        sliderTouchBeginValue = 0
        if subviews.contains(draggedProgressView) {
            draggedProgressView.removeFromSuperview()
        }
        isDragging = false
    }
    
    func sliderValueChange(_ sender: UISlider) {
        guard let avItem = self.avItem else {
            return
        }
        if !self.subviews.contains(draggedProgressView) {
            addSubview(draggedProgressView)
            layoutDraggedContainers()
        }
        let duration = Float64 ((avItem.asset.duration.value)/Int64(avItem.asset.duration.timescale))
        let dragValue = Float64(duration) * Float64(sender.value)
        draggedStatusButton.isSelected = dragValue < sliderTouchBeginValue!
        // 拖动时间展示
        let allTimeString =  self.formatTimDuration(position: Int(dragValue), duration: Int(duration))
        let draggedTimeString = self.formatTimPosition(position: Int(dragValue), duration: Int(duration))
        self.draggedTimeLable.text = String(format: "%@|%@", draggedTimeString, allTimeString)
        self.playControllViewEmbed.positionTimeLab.text = draggedTimeString
    }
}

// MARK: - RXLoaderUrlConnectionDelegate

extension RXPlayerView: RXLoaderUrlConnectionDelegate {
    
    public func didFinishLoadingWithTask(task: RXVideoRequestTask) {
        print("didFinishLoadingWithTask--------\(task.downLoadingOffset)")
        
    }
    
    public func didFailLoadingWithTask(task: RXVideoRequestTask, errorCode: Int) {
        print("didFailLoadingWithTask -------- \(errorCode)")
        playerStatu = PlayerStatus.Failed
        hideLoadingHud()
        showLoadedFailedView()
    }
    
    
}

// MARK: - Listen To the Player (监听播放状态)

extension RXPlayerView {
    
    /// 监听PlayerItem对象
    fileprivate func listenTothePlayer() {
        
        guard let avItem = self.avItem else {return}
        playerTimerObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: Int64(1.0), timescale: Int32(1.0)), queue: nil, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            // 刷新时间UI
            strongSelf.updateTimeSliderValue(avItem: avItem)
            
        }) as? NSObject
        
    }
    
    /// KVO 监听播放状态
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let avItem = object as? AVPlayerItem else {
            return
        }
        if keyPath == "status" {
            if avItem.status == AVPlayerItem.Status.readyToPlay {
                print("Status.readyToPlay")
                playerStatu = .ReadyToPlay // 初始状态为播放
                playControllViewEmbed.playOrPauseBtn.isSelected = true
                updateTimeLableLayout(avItem: avItem)
                
            }else if avItem.status == AVPlayerItem.Status.unknown {
                //视频加载失败，或者未知原因
                playerStatu = .Unknown
                hideLoadingHud()
            } else if avItem.status == AVPlayerItem.Status.failed {
                NLog("Status.failed")
                playerStatu = .Failed
                // 代理出去，在外部处理网络问题
                hideLoadingHud()
                if !playControllViewEmbed.playLocalFile! {  /// 非本地文件播放才显示网络失败
                    showLoadedFailedView()
                }
            }
        } else if keyPath == "loadedTimeRanges" {
            updateLoadingProgress(avItem: avItem)
        } else if keyPath == "playbackBufferEmpty" {
            playerStatu = .Buffering                // 监听播放器正在缓冲数据
            NLog("Status.Buffering")
        } else if keyPath == "playbackLikelyToKeepUp" {                   //监听视频缓冲达到可以播放的状态
            NLog("Status.Playing")
            if !isDragging && playerStatu != .Pause {
                showLoadingHud()
            }
            playerStatu = .Playing
        }
    }
    
    /// 更新时间进度条
    ///
    /// - Parameter avItem: AVPlayerItem
    
    private func updateTimeSliderValue(avItem: AVPlayerItem) {
        
        let timeScaleValue = Int64(avItem.currentTime().timescale) /// 当前时间
        let timeScaleDuration = Int64(avItem.asset.duration.timescale)   /// 总时间
        if avItem.asset.duration.value > 0 && avItem.currentTime().value > 0 {
            let value = avItem.currentTime().value / timeScaleValue  /// 当前播放时间
            let duration = avItem.asset.duration.value / timeScaleDuration /// 视频总时长
            let playValue = Float(value)/Float(duration)
            let stringDuration = formatTimDuration(position: Int(value), duration:Int(duration))
            let stringValue = formatTimPosition(position: Int(value), duration: Int(duration))
            playControllViewEmbed.positionTimeLab.text = stringValue
            playControllViewEmbed.durationTimeLab.text = stringDuration
            if !isDragging {
                playControllViewEmbed.timeSlider.value = playValue
                playedValue = Float(value)                                      // 保存播放进度
            }
            
        }
    }
    
    /// 更新时间显示布局
    ///
    /// - Parameter avItem: AVPlayerItem
    private func updateTimeLableLayout(avItem: AVPlayerItem) {
        let duration = Float(avItem.asset.duration.value)/Float(avItem.asset.duration.timescale)
        let currentTime =  avItem.currentTime().value/Int64(avItem.currentTime().timescale)
        self.videoDuration = Float(duration)
        print("video time length = \(duration) s, current time = \(currentTime) s")
        
        listenTothePlayer()
    }
    
    /// 监听缓存进度
    ///
    /// - Parameter avItem: AVPlayerItem
    private func updateLoadingProgress(avItem: AVPlayerItem) {
        //监听缓存进度，根据时间来监听
        let timeRange = avItem.loadedTimeRanges
        if timeRange.count > 0 {
            let cmTimeRange = timeRange[0] as! CMTimeRange
            let startSeconds = CMTimeGetSeconds(cmTimeRange.start)
            let durationSeconds = CMTimeGetSeconds(cmTimeRange.duration)
            let timeInterval = startSeconds + durationSeconds                    // 计算总进度
            let totalDuration = CMTimeGetSeconds(avItem.asset.duration)
            self.loadedValue = Float(timeInterval)                               // 保存缓存进度
            self.playControllViewEmbed.loadedProgressView.setProgress(Float(timeInterval/totalDuration), animated: true)
        }
    }
    
}

// MARK: - LayoutPageSubviews (UI布局)

extension RXPlayerView {
    
    private func layoutLocalPlayView(_ localView: UIView) {
        self.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(localView.snp.height)
            make.height.equalTo(localView.snp.width)
        }
    }
    private func layoutAllPageSubviews() {
        layoutSelf()
        layoutPlayControllView()
    }
    private func layoutDraggedContainers() {
        layoutDraggedProgressView()
        layoutDraggedStatusButton()
        layoutDraggedTimeLable()
    }
    private func layoutSelf() {
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    private func layoutPlayControllView() {
        playControllViewEmbed.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    private func layoutDraggedProgressView() {
        draggedProgressView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(70)
            make.width.equalTo(150)
        }
    }
    private func layoutDraggedStatusButton() {
        draggedStatusButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(8)
            make.height.equalTo(30)
            make.width.equalTo(40)
        }
    }
    private func layoutDraggedTimeLable() {
        draggedTimeLable.snp.makeConstraints { (make) in
            make.leading.equalTo(8)
            make.trailing.equalTo(-8)
            make.bottom.equalToSuperview()
            make.top.equalTo(draggedStatusButton.snp.bottom)
        }
    }
    private func layoutPauseButton() {
        pauseButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(55)
            make.height.equalTo(55)
        }
    }
    override open func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
    }
}

// MARK: - 时间转换格式

extension RXPlayerView {
    
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
