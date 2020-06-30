
import UIKit
import SnapKit
import AVKit

/* 想要支持 图片 + gif + 视频    首先广告的原理是： 1.首次打开展示本地的默认广告图  2 。进入App,请求广告接口， */

class SwiftAdView: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private lazy var adTimerBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("点击跳过 (\(Int(adTime))S)", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(config.skipBtnTitleColor, for: .normal)
        btn.titleLabel?.font = config.skipBtnFont
        btn.backgroundColor = config.skipBtnBackgroundColor
        btn.layer.cornerRadius = 15
        btn.layer.masksToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 10)
        return btn
    }()
    private let adImage: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    private lazy var coverTapView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickAdView)))
        return view
    }()
    
    private var player: AVPlayer?
    private var timer: Timer!
    private var timer1: Timer?
    
    /// 广告倒计时时间
    var adTime: TimeInterval = 5.0
    var adModel: AdFileModel!
    var config: SwiftAdFileConfig!
    
    var skipBtnClickHandler:(() -> Void)?
    var adClickHandler:((_ adModel: AdFileModel) -> Void)?
    
    deinit {
        print("SwiftAdView ---- deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    init(config: SwiftAdFileConfig, adModel: AdFileModel) {
        self.config = config
        self.adModel = adModel
        self.adTime = config.duration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        if adModel == nil || adModel.adUrl.isEmpty { /// 广告不存在， 直接return
            dismiss(animated: false, completion: nil)
            return
        }
        
        if adModel.adType == .gif {
            setUpGifUI()
            loadTimer()
        } else if adModel.adType == .video {
            setUpVideoUI()
            loadTimer()
        } else {
            setUpImageUI()
            loadTimer()
        }
    }

}

// MARK: - Private - Funcs
private extension SwiftAdView {
    
    func loadTimer() {
        timer = Timer.new(after: adTime.seconds) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.timer1?.invalidate()
            strongSelf.adTime = strongSelf.config.duration
            strongSelf.adTimerBtn.setTitle("点击跳过", for: .normal)
            strongSelf.dissMissAutoAfterSeconds()
        }
        timer1 = Timer.every(1.0.seconds) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.adTime = strongSelf.adTime - 1.0
            strongSelf.adTimerBtn.setTitle("点击跳过 (\(Int(strongSelf.adTime))s)", for: .normal)
        }
        RunLoop.current.add(timer, forMode: .default)
        setUpSkipBtn()
    }
    
    func dissMissAutoAfterSeconds() {
        if config.autoDissMiss && adModel.adType != .video {
            perform(#selector(skipBtnClick), with: nil, afterDelay: 1.0, inModes: [.common])
        }
    }
    
    func setUpCoverView() {
        view.addSubview(coverTapView)
        layoutCoverView()
    }
    
    func setUpSkipBtn() {
        view.addSubview(adTimerBtn)
        layoutTimeBtn()
        adTimerBtn.addTarget(self, action: #selector(skipBtnClick), for: .touchUpInside)
    }
    
    @objc func skipBtnClick() {
        UIView.animate(withDuration: 0.6, animations: {
            self.view.alpha = 0.2
        }) { (finish) in
             self.skipBtnClickHandler?()
             self.dismiss(animated: false, completion: nil)
        }
    }
    
    @objc func didClickAdView() {
        if config.openInSafari {    /// 点击广告 用 safari 打开
            goAdWebPage(adModel.adHerfUrl)
        } else {
            adClickHandler?(adModel)  /// 自定义 点击广告操作
        }
        self.dismiss(animated: false, completion: nil)
    }
    
    func goAdWebPage(_ adUrl: String?) {
        if let urlstring = adUrl {
            let downUrl = String(format: "%@", urlstring)
            if let url = URL(string: downUrl) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:],
                                              completionHandler: {
                                                (success) in
                    })
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
}

// MARK: - 图片展示
private extension SwiftAdView {
    
    func setUpImageUI() {
        view.addSubview(adImage)
        layoutAdImage()
        setUpCoverView()
        if let imageData = SwiftAdFileConfig.getAdDataFromLocal(adModel.adUrl) {
            let type = UIImage.checkImageDataType(data: imageData)
            if type == .gif {
                self.adImage.image = UIImage.gif(data: imageData)
            } else {
                self.adImage.image = UIImage(data: imageData)
            }
        } else {
            self.adImage.image = UIImage.image(url: adModel.adUrl)
        }
    }
}

// MARK: - Gif图片展示
private extension SwiftAdView {

    func setUpGifUI() {
        view.addSubview(adImage)
        layoutAdImage()
        setUpCoverView()
        if let gifData = SwiftAdFileConfig.getAdDataFromLocal(adModel.adUrl) {
            let type = UIImage.checkImageDataType(data: gifData)
            if type == .gif {
                self.adImage.image = UIImage.gif(data: gifData)
            } else {
                self.adImage.image = UIImage(data: gifData)
            }
        } else {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: adModel?.adUrl ?? "") ) {
                  self.adImage.image = UIImage.gif(data: data)
            }
        }
    }
}

// MARK: - 视频展示
private extension SwiftAdView {
    
    func setUpVideoUI() {
        var videoPlayUrl = ""
        var videoURL: URL!
        if let filePath = SwiftAdFileConfig.fileVideoPath(adModel.adUrl) {
            videoPlayUrl = filePath
        } else {
            videoPlayUrl = adModel.adUrl
        }
        if adModel.adUrl.hasSuffix(".m3u8") {
            videoURL = URL(string: videoPlayUrl) //也可以播放网络资源
        } else {
            videoURL = URL(fileURLWithPath: videoPlayUrl)
        }
        let playerItem = AVPlayerItem(url: videoURL)
        //监听播放器进度
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        let player = AVPlayer(playerItem: playerItem)
        //设置大小和位置（全屏）
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        playerLayer.videoGravity = config.videoGravity
        //添加到界面上
        self.view.layer.addSublayer(playerLayer)
        //开始播放
        player.play()
        // 注册APP被挂起 + 进入前台通知
        NotificationCenter.default.addObserver(self, selector: #selector(applicationResignActivity(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActivity(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.player = player
        setUpCoverView()
    }
    
    @objc func playerDidFinishPlaying(_ notiffcation: Notification) {
        if let item = notiffcation.object as? AVPlayerItem {
            item.seek(to: CMTime.zero)
            self.player?.play()
        }
    }
    
    // MARK: - APP将要被挂起
    /// - Parameter sender: 记录被挂起前的播放状态，进入前台时恢复状态
    @objc func applicationResignActivity(_ sender: NSNotification) {
        self.player?.pause()
    }
    
    // MARK: - APP进入前台，恢复播放状态
    @objc func applicationBecomeActivity(_ sender: NSNotification) {
        self.player?.play()

    }
}

// MARK: - Layout Subviews
private extension SwiftAdView {
    
    func layoutAdImage() {
        adImage.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func layoutTimeBtn() {
        adTimerBtn.snp.makeConstraints { (make) in
            make.trailing.equalTo(-15)
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            } else {
                make.top.equalTo(20)
            }
            make.height.equalTo(30)
        }
    }
    
    func layoutCoverView() {
        coverTapView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
