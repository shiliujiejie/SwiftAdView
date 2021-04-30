//
//  GYCircleInfoView.swift
//  GYGestureUnlock
//
//  Created by zhuguangyang on 16/8/24.
//  Copyright © 2016年 Giant. All rights reserved.
//

import UIKit

class GYCircleInfoView: UIView {
    
    init() {
        super.init(frame: CGRect.zero)
        lockViewPrepare()
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        lockViewPrepare()
        
        
    }
    
    func lockViewPrepare() {
        
        self.backgroundColor = CircleBackgroundColor
        
        
        for _ in 0..<9 {
            
            let circl = GYCircle()
            circl.type = CircleTye.circleTypeInfo
            
            addSubview(circl)
            
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let itemViewWH = CircleInfoRadius * 2
        let marginValue = (self.frame.size.width - 3 * itemViewWH) / 3.0
        (self.subviews as NSArray).enumerateObjects({ (object, idx, stop) in
            let row: NSInteger = idx % 3;
            let col = idx / 3;
            
            let x:CGFloat = marginValue * CGFloat(row) + CGFloat(row) * itemViewWH + marginValue/2
            let y: CGFloat = marginValue * CGFloat(col) + CGFloat(col) * itemViewWH + marginValue/2
            
            let frame = CGRect(x: x, y: y, width: itemViewWH, height: itemViewWH)
            
            //设置tag->用于记录密码的单元
            (object as! UIView).tag = idx + 1
            (object as! UIView).frame = frame
        })
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
