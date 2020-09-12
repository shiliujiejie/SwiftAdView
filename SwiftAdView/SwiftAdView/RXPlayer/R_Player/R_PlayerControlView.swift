
import UIKit
import SnapKit

protocol RXPlayerControlViewDelegate: class {
    
    func sliderTouchBegin(_ sender: UISlider)
    func sliderTouchEnd(_ sender: UISlider)
    func sliderValueChange(_ sender: UISlider)
}

class RXPlayerControlView: UIView {
    
    /// 顶部控制栏
    lazy var topControlBarView: UIView = {
        let view = UIView()
       //view.backgroundColor = UIColor(white: 0.2, alpha: 0.2)
        //创建渐变层
        view.layer.addSublayer(topBarBgLayer)
        return view
    }()
    
    lazy var topBarBgLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.height, height: 60)
        gradientLayer.colors =  [UIColor(white: 0.0, alpha: 0.4).cgColor,UIColor(white: 0.0, alpha: 0.2).cgColor,UIColor.clear.cgColor]
        gradientLayer.locations = [0.3, 0.6, 1.0]
        return gradientLayer
    }()
    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(nil, for: .normal)
        button.setImage(RXPublicConfig.foundImage(imageName: "back"), for: .selected)
        button.addTarget(self, action: #selector(closeButtonClick(_:)), for: .touchUpInside)
        return button
    }()
    lazy var munesButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(RXPublicConfig.foundImage(imageName: "share"), for: .normal)
        button.addTarget(self, action: #selector(munesButtonClick(_:)), for: .touchUpInside)
        button.isHidden = true   // 默认隐藏
        return button
    }()
    lazy var videoNameLable: UILabel = {
        let lable = UILabel()
        lable.textColor = .white
        lable.font = UIFont.systemFont(ofSize: 15)
        lable.textAlignment = .left
        return lable
    }()
    /// 加载loadingView
    lazy var loadingView: UIActivityIndicatorView = {
        let loadActivityView = UIActivityIndicatorView(style: .whiteLarge)
        loadActivityView.backgroundColor = UIColor.clear
        return loadActivityView
    }()
    /// 重播按钮
    lazy var replayView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.backgroundColor = UIColor(white: 0.2, alpha: 0.05)
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    lazy var replayButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(RXPublicConfig.foundImage(imageName: "replay"), for: .normal)
        button.addTarget(self, action: #selector(RXPlayerControlView.replayButtonClick(_:)), for: .touchUpInside)
        return button
    }()
    lazy var replayLable: UILabel = {
        let lable = UILabel()
        lable.textAlignment = .center
        lable.text = "重播"
        lable.font = UIFont.systemFont(ofSize: 13)
        lable.textColor = .white
        return lable
    }()
    /// 底部控制栏
    lazy var bottomControlBarView: UIView = {
        let view = UIView()
        //创建渐变层
        view.layer.addSublayer(bottomBarBgLayer)
        return view
    }()
    
    lazy var bottomBarBgLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor,  UIColor(white: 0.0, alpha: 0.2).cgColor,UIColor(white: 0.0, alpha: 0.5).cgColor]
        gradientLayer.locations = [0.3, 0.6, 1.0]
        return gradientLayer
    }()
    
    lazy var loadedProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progress = 0
        progressView.progressTintColor = UIColor.lightGray
        progressView.trackTintColor = UIColor(white: 0.4, alpha: 0.5)
        progressView.backgroundColor = UIColor.clear
        progressView.contentMode = ContentMode.scaleAspectFit
        progressView.tintColor = UIColor.clear
        return progressView
    }()
    lazy var timeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1.0
        slider.backgroundColor = UIColor.clear
        slider.contentMode = ContentMode.scaleAspectFit
        slider.minimumTrackTintColor = UIColor.white
        slider.maximumTrackTintColor = UIColor.clear
        slider.setThumbImage(RXPublicConfig.foundImage(imageName: "sliderflash"), for: .normal)
        slider.setThumbImage(RXPublicConfig.foundImage(imageName: "sliderHightLight"), for: .highlighted)
        slider.addTarget(self, action: #selector(RXPlayerControlView.sliderValueChange(_:)),for:.valueChanged)
        slider.addTarget(self, action: #selector(RXPlayerControlView.sliderAllTouchBegin(_:)), for: .touchDown)
        slider.addTarget(self, action: #selector(RXPlayerControlView.sliderAllTouchEnd(_:)), for: .touchCancel)
        slider.addTarget(self, action: #selector(RXPlayerControlView.sliderAllTouchEnd(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(RXPlayerControlView.sliderAllTouchEnd(_:)), for: .touchUpOutside)
        return slider
    }()
    lazy var positionTimeLab: UILabel = {
        let lable = UILabel()
        lable.textAlignment = .left
        lable.text = "00:00"
        lable.font = UIFont.systemFont(ofSize: 13)
        lable.textColor = .white
        return lable
    }()
    lazy var durationTimeLab: UILabel = {
        let durationLab = UILabel()
        durationLab.textAlignment = .right
        durationLab.text = "00:00"
        durationLab.font = UIFont.systemFont(ofSize: 13)
        durationLab.textColor = .white
        return durationLab
    }()
    lazy var playOrPauseBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(RXPublicConfig.foundImage(imageName: "pause"), for: .normal)
        button.setImage(RXPublicConfig.foundImage(imageName: "play"), for: .selected)
        button.addTarget(self, action: #selector(RXPlayerControlView.playOrPauseBtnClick(_:)), for: .touchUpInside)
        return button
    }()
    lazy var screenLockButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(RXPublicConfig.foundImage(imageName: "unlock"), for: .normal)
        button.setImage(RXPublicConfig.foundImage(imageName: "lockscreen"), for: .selected)
        button.addTarget(self, action: #selector(RXPlayerControlView.screenLockButtonClick(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    lazy var fullScreenBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(RXPublicConfig.foundImage(imageName: "R_fullscreen"), for: .normal)
        button.setImage(RXPublicConfig.foundImage(imageName: "shrinkScreen"), for: .selected)
        button.addTarget(self, action: #selector(RXPlayerControlView.fullScreenBtnClick(_:)), for: .touchUpInside)
        return button
    }()
    /// 手势
    lazy var singleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(singleTapGestureRecognizers(_:)))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        return gesture
    }()
    lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(doubleTapGestureRecognizers(_:)))
        gesture.numberOfTapsRequired = 2
        gesture.numberOfTouchesRequired = 1
        return gesture
    }()
    lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(panGestureRecognizers(_:)))
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = self
        gesture.isEnabled = false          //先让手势不能触发
        return gesture
    }()
    
    var barIsHidden: Bool? = false {
        didSet {
            if let barIsHiden = barIsHidden {
                if barIsHiden {
                    hideTopBottomBar()
                } else {
                    showTopBottomBar()
                }
                if self.fullScreen! && !self.screenIsLock! {
                    screenLockButton.isHidden = barIsHiden
                }
//                if let view = UIApplication.shared.value(forKey: "statusBar") as? UIView {  //根据 barIsHiden 改变状态栏的透明度
//                    if fullScreen! {
//                        view.alpha = barIsHiden ? 0 : 1.0
//                    }
//                }
            }
        }
    }
    ///  是否为全屏状态
    var fullScreen: Bool? = false {
        didSet {
            screenLockButton.isHidden = !fullScreen!     // 只有全屏能锁定屏幕
            fullScreenBtn.isSelected = fullScreen!
            munesButton.isHidden = !fullScreen!          // 只有全屏显示分享按钮
            if !screenLockButton.isHidden {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoHideScreenLockButton), object: nil)
                perform(#selector(autoHideScreenLockButton), with: nil, afterDelay: 5)
            }
            updateTopBarWith(fullScreen: fullScreen!)
            updateBottomBarWith(fullScreen: fullScreen!)
        }
    }
    /// 是否锁屏
    var screenIsLock: Bool? = false {
        didSet {
            if screenIsLock! {
                screenLockButton.isSelected = true
                doubleTapGesture.isEnabled = false
                panGesture.isEnabled = false
                orientationSupport = R_PlayerOrietation.orientationLeftAndRight
            } else {
                screenLockButton.isSelected = false
                doubleTapGesture.isEnabled = true
                panGesture.isEnabled = true
                /// 全屏播放本地时，只支持左右，非直接全屏播放支持上左右
                orientationSupport = playLocalFile ? R_PlayerOrietation.orientationLeftAndRight : R_PlayerOrietation.orientationAll
            }
        }
    }
    /// 是否是  播放本地文件
    var playLocalFile: Bool = false
    
    // MARK: - Delegate
    weak var delegate: RXPlayerControlViewDelegate?
    
    // MARK: - CallBackBlock
    var fullScreenButtonClickBlock: ((_ sender: UIButton) -> ())?
    var playOrPauseButtonClickBlock: ((_ sender: UIButton) -> ())?
    var closeButtonClickBlock: ((_ sender: UIButton) -> ())?
    var muneButtonClickBlock:((_ sender: UIButton) -> ())?
    var replayButtonClickBlock: ((_ sender: UIButton) -> ())?
    var screenLockButtonClickBlock: ((_ sender: UIButton) -> ())?
    var pangeustureAction: ((_ sender: UIPanGestureRecognizer) ->())?
    
    // MARK: - LifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(topControlBarView)
        addSubview(bottomControlBarView)
        addSubview(replayView)
        topControlBarView.addSubview(closeButton)
        topControlBarView.addSubview(videoNameLable)
        topControlBarView.addSubview(munesButton)
        
        bottomControlBarView.addSubview(playOrPauseBtn)
        bottomControlBarView.addSubview(positionTimeLab)
        bottomControlBarView.addSubview(loadedProgressView)
        bottomControlBarView.addSubview(timeSlider)
        bottomControlBarView.addSubview(durationTimeLab)
        bottomControlBarView.addSubview(fullScreenBtn)
        replayView.addSubview(replayButton)
        replayView.addSubview(replayLable)
       
        addSubview(loadingView)
        addSubview(screenLockButton)
        
        layoutAllPageViews()
        addGestureAllRecognizers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// 自动隐藏操作栏
    @objc func autoHideTopBottomBar() {
        barIsHidden = true
    }
    /// 自动隐藏锁屏按钮
    @objc func autoHideScreenLockButton() {
        screenLockButton.isHidden = true
    }
   
}

// MARK: - User -Actions {

extension RXPlayerControlView {
    
   // MARK: - GestureRecognizers - Action
    @objc func singleTapGestureRecognizers(_ sender: UITapGestureRecognizer) {
        if screenIsLock! {                                                    // 锁屏状态下，单击手势只显示锁屏按钮
            screenLockButton.isHidden = !screenLockButton.isHidden
            if !screenLockButton.isHidden {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoHideScreenLockButton), object: nil)
                self.perform(#selector(autoHideScreenLockButton), with: nil, afterDelay: 5)
            }
        }else {
            barIsHidden = !barIsHidden! // 单击改变操作栏的显示隐藏
            if !barIsHidden! {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoHideTopBottomBar), object: nil)
                self.perform(#selector(autoHideTopBottomBar), with: nil, afterDelay: 5)
            }
        }
    }
    
    @objc func doubleTapGestureRecognizers(_ sender: UITapGestureRecognizer) {
        self.playOrPauseBtnClick(playOrPauseBtn) // 双击时直接响应播放暂停按钮点击
    }
    
    @objc func panGestureRecognizers(_ sender: UIPanGestureRecognizer) {
        if let panGestureAction = self.pangeustureAction {
            panGestureAction(sender)
        }
    }
    
    // MARK: - Slider - Action
    @objc func sliderValueChange (_ sender: UISlider) {
        barIsHidden = false
        delegate?.sliderValueChange(sender)
    }
    
    @objc func sliderAllTouchBegin(_ sender: UISlider) {
        barIsHidden = false  // 防止拖动进度时，操作栏5秒后自动隐藏
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoHideTopBottomBar), object: nil)
        delegate?.sliderTouchBegin(sender)
        
    }
    
    @objc func sliderAllTouchEnd(_ sender: UISlider) {
        delegate?.sliderTouchEnd(sender)
        if !barIsHidden! {   // 拖动完成后，操作栏5秒后自动隐藏
            self.perform(#selector(autoHideTopBottomBar), with: nil, afterDelay: 5)
        }
    }
    
    // MARK: - closeButton - Action
    @objc func closeButtonClick(_ sender: UIButton) {
        if self.closeButtonClickBlock != nil {
            self.closeButtonClickBlock!(sender)
        }
    }
    
    // MARK: - munesButton - Action
    @objc func munesButtonClick(_ sender: UIButton) {
        if self.muneButtonClickBlock != nil {
            self.muneButtonClickBlock!(sender)
        }
    }
    
    // MARK: - PlayOrPause - Action
    @objc func playOrPauseBtnClick(_ sender: UIButton) {
        if self.playOrPauseButtonClickBlock != nil {
            self.playOrPauseButtonClickBlock!(sender)
        }
    }
    
    // MARK: - screenLockButton - Action
    @objc func screenLockButtonClick(_ sender: UIButton) {
        screenIsLock = !screenIsLock!
        barIsHidden = screenIsLock
        //        if self.screenLockButtonClickBlock != nil {
        //            self.screenLockButtonClickBlock!(sender)
        //        }
    }
    
    // MARK: - FullScreen - Action
    @objc func fullScreenBtnClick(_ sender: UIButton){
        if self.fullScreenButtonClickBlock != nil {
            self.fullScreenButtonClickBlock!(sender)
        }
    }
    
    // MARK: - ReplayButtonClick
    @objc func replayButtonClick(_ sender: UIButton) {
        if self.replayButtonClickBlock != nil {
            self.replayButtonClickBlock!(sender)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension RXPlayerControlView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UISlider {
            return false
        }
        return true
    }
}

// MARK: - Private - Funcs

extension RXPlayerControlView {
    
    // MARK: - add - GestureRecognizers
    private func addGestureAllRecognizers() {
        self.addGestureRecognizer(singleTapGesture)
        self.addGestureRecognizer(doubleTapGesture)
        self.addGestureRecognizer(panGesture)
        // 解决点击当前view时候响应其他控件事件
        singleTapGesture.delaysTouchesBegan = true
        doubleTapGesture.delaysTouchesBegan = true
        panGesture.delaysTouchesBegan = true
        panGesture.delaysTouchesEnded = true
        panGesture.cancelsTouchesInView = true
        // 双击，滑动 ，失败响应单击事件,
        singleTapGesture.require(toFail: doubleTapGesture)
        singleTapGesture.require(toFail: panGesture)
    }
    
    
    /// 隐藏操作栏，带动画
    private func hideTopBottomBar() {
        topControlBarView.snp.updateConstraints { (make) in
            make.height.equalTo(0)
        }
        bottomControlBarView.snp.updateConstraints { (make) in
            make.height.equalTo(fullScreen! ? 10 : 90)
        }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.layoutIfNeeded()
        }) { (finish) in
            self.bottomControlBarView.isHidden = true
            self.topControlBarView.isHidden = true
        }
    }
    
    ///显示操作栏，带动画
    private func showTopBottomBar() {
        topControlBarView.isHidden = false
        bottomControlBarView.isHidden = false
        topControlBarView.snp.updateConstraints { (make) in
            make.height.equalTo(fullScreen! ? 60 : 40)
        }
        
        bottomControlBarView.snp.updateConstraints { (make) in
            make.height.equalTo(90)
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.layoutIfNeeded()
        })
    }
    
}

// MARK : - Layout All Subviews

extension RXPlayerControlView {
    
    private func layoutAllPageViews() {
        layoutTopControlBarView()
        layoutCloseButton()
        layoutMunesButton()
        layoutVideoNameLable()
        layoutBottomControlBarView()
       
        layoutPositionTimeLab()
        layoutDurationTimeLab()
        layoutLoadedProgressView()
        layoutTimeSlider()
        layoutPlayOrPauseBtn()
        layoutFullScreenBtn()
        layoutLoadingActivityView()
        layoutreplayView()
        layoutReplayButton()
        layoutReplayLable()
        layoutScreenLockButton()
        self.layoutIfNeeded()
    }
    private func layoutBottomControlBarView() {
        bottomControlBarView.snp.makeConstraints { (make) in
            make.leading.bottom.trailing.equalTo(0)
            make.height.equalTo(90)
        }
    }
    private func layoutCloseButton() {
        closeButton.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.leading.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
    }
    private func layoutMunesButton() {
        munesButton.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.trailing.equalToSuperview()
            make.width.height.equalTo(40)
        }
    }
    private func layoutVideoNameLable() {
        videoNameLable.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.bottom.equalToSuperview()
            make.leading.equalTo(closeButton.snp.trailing).offset(5)
            make.trailing.equalToSuperview().offset(80)
        }
    }
    private func layoutLoadingActivityView() {
        loadingView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
    }
    private func layoutreplayView() {
        replayView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(70)
            make.height.equalTo(70)
        }
    }
    private func layoutReplayButton() {
        replayButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(5)
            make.height.equalTo(35)
            make.width.equalTo(35)
        }
    }
    private func layoutScreenLockButton() {
        screenLockButton.snp.makeConstraints { (make) in
            make.leading.equalTo((RXDeviceModel.isiPhoneXSeries() || RXDeviceModel.isSimulator()) ? 50 : 10)
            make.centerY.equalToSuperview()
            make.height.equalTo(45)
            make.width.equalTo(45)
        }
    }
    private func layoutReplayLable() {
        replayLable.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(25)
        }
    }
    private func layoutTopControlBarView() {
        topControlBarView.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalTo(0)
            make.height.equalTo(40)
        }
    }
    private func layoutPositionTimeLab() {
        positionTimeLab.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.leading.equalTo(10)
            make.height.equalTo(20)
        }
    }
    private func layoutDurationTimeLab() {
        durationTimeLab.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.trailing.equalTo(-10)
            make.height.equalTo(20)
        }
    }
    private func layoutLoadedProgressView() {
        loadedProgressView.snp.makeConstraints { (make) in
            make.centerY.equalTo(positionTimeLab.snp.bottom).offset(15)
            make.height.equalTo(1.5)
            make.leading.equalTo(positionTimeLab)
            make.trailing.equalTo(durationTimeLab)
        }
    }
    private func layoutTimeSlider() {
        timeSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(loadedProgressView.snp.centerY).offset(-0.5)  // 调整一下进度条和 加载进度条的位置
            make.leading.equalTo(loadedProgressView.snp.leading)
            make.trailing.equalTo(loadedProgressView.snp.trailing)
            make.height.equalTo(30)
        }
    }
    private func layoutPlayOrPauseBtn() {
        playOrPauseBtn.snp.makeConstraints { (make) in
            make.top.equalTo(timeSlider.snp.bottom)
            make.leading.equalTo(timeSlider)
            make.width.height.equalTo(30)
        }
    }
    private func layoutFullScreenBtn() {
        fullScreenBtn.snp.makeConstraints { (make) in
            make.top.equalTo(timeSlider.snp.bottom)
            make.trailing.equalTo(timeSlider)
            make.height.width.equalTo(30)
        }
    }
    private func updateTopBarWith(fullScreen: Bool) {
        topControlBarView.snp.updateConstraints { (make) in
            make.height.equalTo(fullScreen ? 50 : 40)
        }
        closeButton.snp.updateConstraints { (make) in
            make.top.equalTo(fullScreen ? 10 : 0)
            make.width.equalTo(fullScreen ? 30 : 0)
            if fullScreen {
                make.leading.equalTo((RXDeviceModel.isiPhoneXSeries() || RXDeviceModel.isSimulator()) ? 50 : 10)
            } else {
                make.leading.equalTo(0)
            }
        }
        videoNameLable.snp.updateConstraints { (make) in
            make.top.equalTo(fullScreen ? 10 : 0)
        }
        munesButton.snp.updateConstraints { (make) in
            make.top.equalTo(fullScreen ? 10 : 0)
            if fullScreen {
                make.trailing.equalTo((RXDeviceModel.isiPhoneXSeries() || RXDeviceModel.isSimulator()) ? -50 : -10)
            } else {
                make.trailing.equalTo(-10)
            }
        }
    }
    private func updateBottomBarWith(fullScreen: Bool) {
        positionTimeLab.snp.updateConstraints { (make) in
            if fullScreen {
                make.leading.equalTo((RXDeviceModel.isiPhoneXSeries() || RXDeviceModel.isSimulator()) ? 50 : 10)
            } else {
                make.leading.equalTo(10)
            }
        }
        durationTimeLab.snp.updateConstraints { (make) in
            if fullScreen {
                 make.trailing.equalTo((RXDeviceModel.isiPhoneXSeries() || RXDeviceModel.isSimulator()) ? -50 : -10)
            } else {
                 make.trailing.equalTo(-10)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        topControlBarView.layoutIfNeeded()
        bottomControlBarView.layoutIfNeeded()
        if fullScreen! {
            topBarBgLayer.frame = CGRect(x: 0, y: 0, width: topControlBarView.frame.size.width  , height: topControlBarView.frame.size.height)
            bottomBarBgLayer.frame = CGRect(x: 0, y: 0, width: bottomControlBarView.frame.size.width , height: 90)
        } else {
            topBarBgLayer.frame = CGRect(x: 0, y: 0, width: topControlBarView.frame.size.width, height: topControlBarView.frame.size.height)
            bottomBarBgLayer.frame = CGRect(x: 0, y: 0, width: bottomControlBarView.frame.size.width, height: 90)
        }
    }
}
