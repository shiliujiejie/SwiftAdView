//
//  NicooNetWorkAlert.swift
//  NicooPlayer
//
//  Created by 小星星 on 2018/8/23.
//

import UIKit

/// 网络提示框， 用于播放远程视频时，网络变化，或4G网下播放，提示用户

open class NicooNetWorkAlert: UIView {
    
    static private let kAlertViewWidth: CGFloat = 269.5
    static private let kAlertViewHeight: CGFloat = 125
    
    /// 存放按钮title
    public var itemTitles: [String]?
    public var itemButtonClick:((_ index: Int) ->Void)?
    /// 是否允许当前视频集在4G网下播放
    public var allowedWWanPlayInCurrentVideoGroups: Bool = false
    private let msgLable: UILabel = {
        let lable = UILabel()
        lable.numberOfLines = 0
        lable.font = UIFont.systemFont(ofSize: 16)
        lable.textAlignment = .center
        return lable
    }()
    private let alertView: UIView = {
        let alertView = UIView()
        alertView.backgroundColor = UIColor.white
        alertView.layer.cornerRadius = 10
        alertView.layer.masksToBounds = true
        return alertView
    }()
    
    deinit {
        NLog("网络弹框被释放")
    }
    
    public init(frame: CGRect, itemButtonTitles: [String]?, message: String) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(white: 0, alpha: 0.3)
        itemTitles = itemButtonTitles
        msgLable.text = message
        alertView.addSubview(msgLable)
        addSubview(alertView)
        layoutPageSubviews()
        
        loadButtons()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - Public funcs in the component

public extension NicooNetWorkAlert {
    
    /// 展示
    public func showInWindow() {
        orientationSupport = NicooPlayerOrietation.orientationPortrait     ///这里展示无网操作时。将屏幕支持改为竖屏
        if let window = UIApplication.shared.keyWindow {
            if !window.subviews.contains(self) {
                window.addSubview(self)
                self.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
        }
    }
    
    /// 隐藏
    
    public func hideFromWindow() {
        if self.superview != nil {
            self.removeFromSuperview()
        }
    }
    
}

// MARK: - Private funcs

private extension NicooNetWorkAlert {
    
    // MARK: - User Actions
    
    @objc func menuButtonClick(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else {
            return
        }
        guard let titles = itemTitles, titles.count > 0 else {
            return
        }
        guard let index = titles.index(of: title) else {
            return
        }
        itemButtonClick?(index)
        self.removeFromSuperview()
    }
    
    // MARK : - Private funcs
    
    func createButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.layer.borderColor = UIColor(red: 218.0/255.0, green: 218.0/255.0, blue: 222.0/255.0, alpha: 1).cgColor
        button.layer.borderWidth = 0.4
        return button
    }
    
    func loadButtons() {
        guard let titles = itemTitles, titles.count > 0 else {
            return
        }
        let buttonWidth = NicooNetWorkAlert.kAlertViewWidth / CGFloat(titles.count)
        for i in 0 ..< titles.count {
            let title = titles[i]
            let button = createButton()
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            button.setTitleColor(i == 0 ? UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1) : UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1), for: .normal)
            button.setTitleColor(UIColor.gray, for: .highlighted)
            button.addTarget(self, action: #selector(NicooNetWorkAlert.menuButtonClick(_:)), for: .touchUpInside)
            alertView.addSubview(button)
            button.snp.makeConstraints { (make) in
                make.width.equalTo(buttonWidth)
                make.bottom.equalTo(0)
                make.top.equalTo(msgLable.snp.bottom).offset(1)
                make.leading.equalTo(buttonWidth * CGFloat(i))
            }
        }
    }
    
}

// MARK: - Layout

private extension NicooNetWorkAlert {
    
    func layoutPageSubviews() {
        layoutAlertView()
        layoutMessageLabel()
    }
    
    func layoutAlertView() {
        alertView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(269.5)
            make.height.equalTo(125)
        }
    }
    
    func layoutMessageLabel() {
        msgLable.snp.makeConstraints { (make) in
            make.leading.equalTo(10)
            make.trailing.equalTo(-10)
            make.top.equalTo(10)
            make.bottom.equalTo(-40)
        }
    }
}
