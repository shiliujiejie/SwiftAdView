//
//  PlayerCoverView.swift
//  SwiftAdView
//
//  Created by mac on 2020-03-11.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit

protocol PlayerCoverDelegate: class {
    func moveProgressIn(point: Double)
    func progressDraging(progress: Double)
    func singleTapCoverView()
    func doubleTapCoverViewAt(point: CGPoint)
}

class PlayerCoverView: UIView {
    /// 底部控制栏
    lazy var controlView: UIView = {
        let view = UIView()
        view.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: configModel.controlViewHeight)
        view.backgroundColor = configModel.controlViewColor
        return view
    }()
    lazy var progressView: UIProgressView = {
        let progress = UIProgressView()
        progress.progress = 0
        progress.progressTintColor = configModel.progressTintColor
        progress.trackTintColor = configModel.progreesStrackTintColor
        progress.backgroundColor = configModel.progressBackgroundColor
        progress.contentMode = ContentMode.scaleAspectFit
        return progress
    }()
    // 加载
    let loadingBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.isHidden = true
        return view
    }()
    var draggedTimeLable: UILabel = {
        let lable = UILabel()
        lable.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        lable.layer.cornerRadius = 6
        lable.layer.masksToBounds = true
        lable.textColor = UIColor.white
        lable.font = UIFont.boldSystemFont(ofSize: 16)
        lable.textAlignment = .center
        lable.isHidden = true
        return lable
    }()
     /// 手势
    lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(panGestureRecognizers(_:)))
        gesture.maximumNumberOfTouches = 1
        return gesture
    }()
    lazy var progressTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(singleTapGestureRecognizers(_:)))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        return gesture
    }()
    lazy var coverTapGesture: UITapGestureRecognizer = {
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
    ///是否正在拖动进度
    var draging: Bool = false {
        didSet {
            progressView.snp.updateConstraints { (make) in
                make.height.equalTo(draging ? configModel.selectedProgrossHight : configModel.progressHeight)
            }
        }
    }

    /// 试图配置
    var configModel: PlayerViewConfig!
    
    weak var delegate: PlayerCoverDelegate?
    
    convenience init(config: PlayerViewConfig) {
        self.init()
        configModel = config
        addSubview(controlView)
        addSubview(draggedTimeLable)
        controlView.addSubview(progressView)
        controlView.addSubview(loadingBar)
        layoutPageSubviews()
        controlView.addGestureRecognizer(progressTapGesture)
        controlView.addGestureRecognizer(panGesture)
        self.addGestureRecognizer(coverTapGesture)
        self.addGestureRecognizer(doubleTapGesture)
        coverTapGesture.require(toFail: doubleTapGesture)
        createCoverLayer()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createCoverLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = controlView.bounds
        //设置渐变的主颜色
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor(white: 0.0, alpha: 0.05).cgColor,  UIColor(white: 0.0, alpha: 0.1).cgColor]
        gradientLayer.locations = [0.9, 0.95, 1.0]
        //将gradientLayer作为子layer添加到主layer上
        controlView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
}
 // MARK: - GestureRecognizers - Action
extension  PlayerCoverView {

    @objc func panGestureRecognizers(_ sender: UIPanGestureRecognizer) {
        draging = true
        let touchPoint = sender.location(in: self)
        let progress = Double(touchPoint.x/UIScreen.main.bounds.width)
        //print("panpanopan --- touchpoint.x = \(touchPoint.x) touchPoint.y = \(touchPoint.y) progress = \(progress)")
        switch sender.state {
        case .began:
            draggedTimeLable.isHidden = false
            break
        case .changed:
            delegate?.progressDraging(progress: progress)
            progressView.setProgress(Float(progress), animated: false)
            break
        case .ended:
            draggedTimeLable.isHidden = true
            delegate?.moveProgressIn(point: progress)
            break
        default:
            break
        }
    }
    
    @objc func singleTapGestureRecognizers(_ sender: UITapGestureRecognizer) {
        if sender == coverTapGesture {  // 暂停/播放
            delegate?.singleTapCoverView()
        } else if sender == progressTapGesture { /// 进度条点击
            draging = true
            let touchPoint = sender.location(in: controlView)
            let progress = Double(touchPoint.x/UIScreen.main.bounds.width)
            //print(" tappppp touchpoint.x = \(touchPoint.x) touchPoint.y = \(touchPoint.y) progress = \(progress)")
            progressView.setProgress(Float(progress), animated: false)
            delegate?.moveProgressIn(point: progress)
        }
    }
    
    @objc func doubleTapGestureRecognizers(_ sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: self)
        delegate?.doubleTapCoverViewAt(point: touchPoint)
    }
    
}

//MARK: - LoadingAnimation
extension PlayerCoverView {
    func startLoading(_ isStart: Bool = true) {
        loadingBar.isHidden = false
        progressView.isHidden = true
        controlView.isUserInteractionEnabled = false
        loadingBar.layer.removeAllAnimations()
        loadingBar.backgroundColor = configModel.loadingBarColor
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 0.6
        animationGroup.beginTime = CACurrentMediaTime()
        animationGroup.repeatCount = .infinity
        animationGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        let scaleAnimX = CABasicAnimation()
        scaleAnimX.keyPath = "transform.scale.x"
        scaleAnimX.fromValue = 1.0
        scaleAnimX.toValue = 10.0 * UIScreen.main.bounds.width
        
        let scaleAnimY = CABasicAnimation()
        scaleAnimY.keyPath = "transform.scale.y"
        scaleAnimY.fromValue = 1.0
        scaleAnimY.toValue = 0.3
        
        let alphaAnim = CABasicAnimation()
        alphaAnim.keyPath = "opacity"
        alphaAnim.fromValue = 1.0
        alphaAnim.toValue = 0.35
        
        animationGroup.animations = [scaleAnimX, scaleAnimY, alphaAnim]
        loadingBar.layer.add(animationGroup, forKey: nil)
    }
    
    func stopLoading() {
        controlView.isUserInteractionEnabled = true
        loadingBar.layer.removeAllAnimations()
        loadingBar.isHidden = true
        progressView.isHidden = false
    }
    override public func layoutSubviews() {
        super.layoutSubviews()
        let y = configModel.controlViewHeight - configModel.loadingBarHeight
        loadingBar.frame = CGRect(x: self.bounds.midX - 0.5, y: y, width: 0.1, height: configModel.loadingBarHeight)
    }
}

//MARK: - Layout
private extension PlayerCoverView {
    func layoutPageSubviews() {
        layoutControlView()
        layoutProgressView()
        layoutDraggedView()
    }
    func layoutControlView() {
        controlView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(-configModel.controlBarBottomInset)
            make.height.equalTo(configModel.controlViewHeight)
        }
    }
    func layoutProgressView() {
        progressView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalTo(controlView)
            make.height.equalTo(configModel.progressHeight)
        }
    }
    func layoutDraggedView() {
        draggedTimeLable.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(70)
            make.width.equalTo(150)
        }
    }
  
}
