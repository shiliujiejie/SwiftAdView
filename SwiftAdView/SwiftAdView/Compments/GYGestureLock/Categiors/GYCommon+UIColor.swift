//
//  GYCommon+UIColor.swift
//  GYGestureUnlock
//
//  Created by zhuguangyang on 16/8/19.
//  Copyright © 2016年 Giant. All rights reserved.
//

import UIKit


extension UIColor {
    
    class func colorWithRgba(_ r: CGFloat, g: CGFloat, b: CGFloat, a:CGFloat)-> UIColor {
        
        
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    
    }
    
}
