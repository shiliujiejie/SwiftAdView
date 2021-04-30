//
//  CALayer+Anim.swift
//  GYGestureUnlock
//
//  Created by zhuguangyang on 16/8/24.
//  Copyright © 2016年 Giant. All rights reserved.
//

import UIKit

extension CALayer {
    
    func shake() {
        let kfa = CAKeyframeAnimation.init(keyPath: "transform.translation.x")
        let s:CGFloat = 5.0

        
        kfa.values = [(-s),(0),s,0,-s,0,s,0]
        
        //晃动时长
        kfa.duration = 0.3
        
        //重复次数
        kfa.repeatCount = 2
        
        //移除
        kfa.isRemovedOnCompletion = true
        
        add(kfa, forKey: "shake")
        
    }
    
}
