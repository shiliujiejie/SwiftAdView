//
//  GYLockLabel.swift
//  GYGestureUnlock
//
//  Created by zhuguangyang on 16/8/24.
//  Copyright © 2016年 Giant. All rights reserved.
//

import UIKit

class GYLockLabel: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        viewPrepare()
        
    }
    
    func viewPrepare() {
        self.font = UIFont.systemFont(ofSize: 14)
        self.textAlignment = .center
    }
    
    /**
     普通提示信息
     
     - parameter msg: 信息
     */
    func showNormalMag(_ msg: NSString){
        self.text = msg as String
        self.textColor = textColorNormalState
    }
    
    /**
     警示信息
     
     - parameter msg: 信息
     */
    func showWarnMsg(_ msg: String){
        self.text = msg
        self.textColor = textColorWarningState
    }
    
    /**
     警示信息(shake)
     
     - parameter msg: 警示信息
     */
    func showWarnMsgAndShake(_ msg:String) {
        
        self.text = msg
        self.textColor = textColorWarningState
        
        //添加一个shake动画
        self.layer.shake()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewPrepare()
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
