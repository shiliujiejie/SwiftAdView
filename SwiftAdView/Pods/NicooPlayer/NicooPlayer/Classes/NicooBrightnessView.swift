//
//  NicooBrightnessView.swift
//  NicooPlayer
//
//  Created by 小星星 on 2018/6/19.
//

import UIKit
import SnapKit


extension UINavigationController { // 用于状态栏的显示，样式
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        guard let vc = self.viewControllers.last else { return UIStatusBarStyle.default }
        return vc.preferredStatusBarStyle
    }
}

class NicooBrightnessView: UIView {
    
    lazy var brightnessImage: UIImageView = {
        let imageV = UIImageView(image: NicooImgManager.foundImage(imageName: "player_brightness"))
        return imageV
    }()
    lazy var titleLab: UILabel = {
        let lable = UILabel(frame: CGRect(x: 0, y: 5, width: self.bounds.size.width, height: 25))
        lable.font = UIFont.boldSystemFont(ofSize: 17)
        lable.tintColor = UIColor.white
        lable.textAlignment = .center
        lable.text = "亮度"
        return lable
    }()
    lazy var fakeSliderBackView: UIView = {
        let view = UIView(frame: CGRect(x: 12, y: 132, width: self.bounds.size.width - 24, height: 7))
        view.backgroundColor = UIColor.darkText
        return view
    }()
    lazy var tipsViewArray: [UIView] = {
        let tips = [UIView]()
        return tips
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius  = 10
        self.layer.masksToBounds = true
        self.loadUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func loadUI() {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 155, height: 155))
        toolBar.alpha = 0.95
        self.addSubview(toolBar)
        self.addSubview(titleLab)
        self.addSubview(brightnessImage)
        self.addSubview(fakeSliderBackView)
        self.layoutAllSubviews()
        self.createTipsViews()
        
    }
    fileprivate func createTipsViews() {
        let tipWidth = (fakeSliderBackView.bounds.size.width - 17.0)/16.0 // 每个TIPS间隔1
        let tipHight = 5
        // let tipY = 1
        for index in 0..<17 {
            let tipsX = CGFloat(index) * (tipWidth + 1) + 1
            let tipsView = UIView()
            tipsView.backgroundColor = UIColor.white
            self.fakeSliderBackView.addSubview(tipsView)
            self.tipsViewArray.append(tipsView)
            tipsView.snp.makeConstraints { (make) in
                make.leading.equalTo(tipsX)
                make.centerY.equalToSuperview()
                make.width.equalTo(tipWidth)
                make.height.equalTo(tipHight)
            }
        }
        self.updateBrightness(UIScreen.main.brightness)
        
    }
    
    
    func updateBrightness(_ value: CGFloat) {
        let stage = 1.0/15.0
        let level = value / CGFloat(stage)
        for index in 0..<self.tipsViewArray.count {
            let tipsView = self.tipsViewArray[index]
            if index <= Int(level) {
                tipsView.isHidden = false
            }else {
                tipsView.isHidden = true
            }
        }
    }
    fileprivate func layoutAllSubviews() {
        titleLab.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(5)
            make.height.equalTo(26)
        }
        brightnessImage.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(79)
            make.height.equalTo(76)
        }
        fakeSliderBackView.snp.makeConstraints { (make) in
            make.leading.equalTo(12)
            make.trailing.equalTo(-12)
            make.bottom.equalTo(-15)
            make.height.equalTo(7)
        }
    }
}
