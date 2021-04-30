
//
//  GYCircleView.swift
//  GYGestureUnlock
//
//  Created by zhuguangyang on 16/8/19.
//  Copyright © 2016年 Giant. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


enum CircleViewType: Int {
    /// 设置手势密码
    case circleViewTypeSetting = 1
    /// 登陆手势密码
    case circleViewTypeLogin
    /// 验证旧手势密码
    case circleViewTypeVerify
}

protocol GYCircleViewDelegate {
    
    /**
     *  连线个数少于4个时，通知代理
     *
     *  @param view    circleView
     *  @param type    type
     *  @param gesture 手势结果
     */
    func circleViewConnectCirclesLessThanNeedWithGesture(_ view: GYCircleView,type: CircleViewType,gesture: String)
    
    /**
     *  连线个数多于或等于4个，获取到第一个手势密码时通知代理
     *
     *  @param view    circleView
     *  @param type    type
     *  @param gesture 第一个次保存的密码
     */
    func circleViewdidCompleteSetFirstGesture(_ view: GYCircleView,type: CircleViewType,gesture: String)
    
    /**
     *  获取到第二个手势密码时通知代理
     *
     *  @param view    circleView
     *  @param type    type
     *  @param gesture 第二次手势密码
     *  @param equal   第二次和第一次获得的手势密码匹配结果
     */
    func circleViewdidCompleteSetSecondGesture(_ view: GYCircleView,type: CircleViewType,gesture: String,result: Bool)
    
    func circleViewdidCompleteLoginGesture(_ view: GYCircleView,type: CircleViewType,gesture: String,result: Bool)
    
}

class GYCircleView: UIView {
    
    /// 是否裁剪
    var clip: Bool = true
    
    /// 是否有箭头
    var _arrow: Bool?
    var arrow: Bool?
        {
        set {
            _arrow = newValue
            (self.subviews as NSArray).enumerateObjects({ (circle,_,_) in
                let circler = circle as! GYCircle
                circler.isArrow = newValue!
                
                
            })
            
        }
        get {
            return _arrow
        }
    }
    /// 解锁类型
    var type: CircleViewType?
    
    var delegate: GYCircleViewDelegate?
    
    /// 选中圆的集合
    var circleSet: NSMutableArray?
    
    /// 当前点
    var currentPoint: CGPoint?
    
    /// 数组清空标志
    var hasClean: Bool?
    //    @objc(init)
    init(){
        
        super.init(frame: CGRect.zero)
        lockViewPrepare()
        circleSet = NSMutableArray()
        //        super.init()
    }
    //    convenience init() {
    //        self.init()
    //        lockViewPrepare()
    //    }
    
    
    
    init(frame: CGRect,type: CircleViewType,clip: Bool,arrow: Bool) {
        super.init(frame: frame)
        self.type = type
        self.clip = clip
        self.arrow = arrow
        lockViewPrepare()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.lockViewPrepare()
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func lockViewPrepare() {
        
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width - CircleViewEdgeMargin * 2, height: UIScreen.main.bounds.size.width - CircleViewEdgeMargin * 2)
        self.center = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: CircleViewCenterY)
        
        /**
         *  默认裁剪子控件
         */
        self.clip = true
        self.arrow = true
        
        self.backgroundColor = CircleBackgroundColor
        
        for _ in 0..<9 {
            
            let circle = GYCircle()
            circle.type = CircleTye.circleTypeGesture
            circle.isArrow = self.arrow!
            
            
            addSubview(circle)
            
        }
    }
    
    /**
     addSubview时会调用 排版子View
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        let itemViewWH = CircleRadius * 2
        let marginValue = (self.frame.size.width - 3 * itemViewWH) / 3.0
        (self.subviews as NSArray).enumerateObjects({ (object, idx, stop) in
            let row: NSInteger = idx % 3;
            let col = idx / 3;
            
            let x:CGFloat = marginValue * CGFloat(row) + CGFloat(row) * itemViewWH + marginValue/2
            let y: CGFloat = marginValue * CGFloat(col) + CGFloat(col) * itemViewWH + marginValue/2
            
            let frame = CGRect(x: x, y: y, width: itemViewWH, height: itemViewWH)
            
            //设置tag->用于记录密码的单元
            (object as! GYCircle).tag = idx + 1
            (object as! GYCircle).frame = frame
        })
        
        
    }
    
    override func draw(_ rect: CGRect) {
        //如果没有任何选中按钮  直接return
        if self.circleSet == nil || self.circleSet?.count == 0 {
            return
        }
        
        let color: UIColor?
        if getCircleState() == CircleState.circleStateError {
            color = CircleConnectLineErrorColor
        } else {
            color = CircleConnectLineNormalColor
        }
        
        //绘制图案
        connectCirclesInRect(rect, color: color!)
        
    }
    
    //MARK: - 连线绘制图案(以设定颜色绘制)
    
    /**
     将选中的圆形以color颜色链接起来
     
     - parameter rect:  图形上下文
     - parameter color: 连线颜色
     */
    func connectCirclesInRect(_ rect: CGRect, color: UIColor) {
        
        //获取上下文
        let ctx = UIGraphicsGetCurrentContext()
        
        //添加路径
        ctx?.addRect(rect)
        
        //是否剪裁
        clipSubviewsWhenConnectInContext(ctx!, clip: self.clip)
        
        //剪裁上下文
        ctx?.clip()
//        CGContextEOClip(ctx!)
        
        //遍历数组中的circle
        let num = self.circleSet?.count
        
        for i in 0..<num! {
            //取出选中按钮
            let circle = self.circleSet![i] as! GYCircle
            
            if i == 0 {//第一个按钮
                ctx!.move(to: CGPoint(x: circle.center.x, y: circle.center.y))
                
                
            } else {
                //全部是线
                ctx!.addLine(to: CGPoint(x: circle.center.x, y: circle.center.y))
            }
            
        }
        weak var weakSelf = self
        //连接最后一个按钮到手指当前触摸的点
        if self.currentPoint!.equalTo(CGPoint.zero) == false {
            (subviews as NSArray).enumerateObjects({ (circle, idx, stop) in
                
                if weakSelf?.getCircleState() == CircleState.circleStateError || weakSelf?.getCircleState() == CircleState.circleStateLastOneError {
                    //如果是错误的狀態下不连接到当前点
                } else {
                    ctx?.addLine(to: CGPoint(x: (self.currentPoint?.x)!, y: (self.currentPoint?.y)!))
                }
            })
        }
        
        //线条转角样式
        ctx?.setLineCap(CGLineCap.round)
        ctx?.setLineJoin(CGLineJoin.round)
        
        //设置绘图的属性
        ctx?.setLineWidth(CircleConnectLineWidth)
        
        //线条颜色
        color.set()
        
        //渲染路径
        ctx?.strokePath()
    }
    
    //MARK: - 是否剪裁
    func clipSubviewsWhenConnectInContext(_ ctx: CGContext,clip:Bool) {
        
        if clip {
            //遍历所有子控件
            (subviews as NSArray).enumerateObjects({ (circle, idx, stop) in
                
                //确定剪裁的形状
                ctx.addEllipse(in: (circle as! GYCircle).frame)
                
            })
        }
        
    }
    //MARK:- 手势方法 began - moved - end
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        gestureEndResetMembers()
        currentPoint = CGPoint.zero
        let touch = (touches as NSSet).anyObject()
        
        let point = (touch as AnyObject).location(in: self)
        (subviews as NSArray).enumerateObjects({ (circle, idx, stop) in
            
            
            let cir = circle as! GYCircle
            
            if cir.frame.contains(point) {
                
                
                cir.state = CircleState.circleStateSelected
                self.circleSet?.add(cir)
                DLog("添加子View的tag:\(cir.tag)")
            }
            
            
        })
        
        //数组中最后一个对象的处理
        circleSetLastObjectWithState(CircleState.circleStateLastOneSelected)
        setNeedsDisplay()
        
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentPoint = CGPoint.zero
        let touch = (touches as NSSet).anyObject()
        
        //获取手势所在的点坐标
        let point = (touch as AnyObject).location(in: self)
        (subviews as NSArray).enumerateObjects({ (circle, idx, stop) in
            
            let cir = circle as! GYCircle
            if cir.frame.contains(point) {
                
                //self.circleSet?.containsObject(cir) != nil
                // 判断数组中是否包含此view 包含不添加 不包含则添加
                if self.circleSet!.contains(cir) {
                    //                    DLog("添加子View的tag:\(cir.tag)")
                    //                    self.circleSet?.addObject(cir)
                    //                    self.calAngleAndconnectTheJumpedCircle()
                } else {
                    self.circleSet?.add(cir)
                    
                    // move过程中的连线(包含跳跃连线的处理)
                    self.calAngleAndconnectTheJumpedCircle()
                }
            } else {
                self.currentPoint = point
            }
            
        })
        
        guard (self.circleSet != nil) else {
            return
        }
        
        (self.circleSet! as NSArray).enumerateObjects({ (circle, idx, stop) in
            
            let circlel = circle as! GYCircle
            circlel.state = CircleState.circleStateSelected
            
            // 如果是登錄或者验证原手势密码  就改为对应的狀態
            if self.type != CircleViewType.circleViewTypeSetting {
                circlel.state = CircleState.circleStateLastOneSelected
            }
            
        })
        
        //数组中最后一个对象的处理
        self.circleSetLastObjectWithState(CircleState.circleStateLastOneSelected)
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.hasClean = false
        guard self.circleSet != nil else {
            return
        }
        let gesture = self.getGestureResultFromCircleSet(self.circleSet!)
        
        let length = gesture.length
        
        if length == 0 {
            return
        }
        
        //手势绘制结果处理
        switch self.type! {
        case CircleViewType.circleViewTypeSetting:
            gestureEndByTypeSettingWithGesture(gesture, length: CGFloat(length))
            break
        case CircleViewType.circleViewTypeLogin:
            gestureEndByTypeLoginWithGesture(gesture, length: CGFloat(length))
        case CircleViewType.circleViewTypeVerify:
            gestureEndByTypeVerifyWithGesture(gesture, length: CGFloat(length))
            
        }
        
        //手势结束后是否错误回显重绘，取决于是否延时清空数组和狀態复原
        errorToDisplay()
        
    }
    
    func errorToDisplay() {
        weak var weakSelf = self
        if getCircleState() == CircleState.circleStateError || getCircleState() == CircleState.circleStateLastOneError {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(kdisplayTime) * NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
                
                weakSelf?.gestureEndResetMembers()
            })
            
            
        } else {
            gestureEndResetMembers()
        }
        
    }
    
    //MARK:- 手势结束时的清空操作
    func gestureEndResetMembers() {
        
        /**
         *  保证线程安全
         */
        synchronized(self) {
            guard self.hasClean != nil else {
                return
            }
            if !self.hasClean! {
                
                //手势完毕、选中的圆回归普通狀態
                self.changeCircleInCircleSetWithState(CircleState.circleStateNormal)
                
                //清空数组
                self.circleSet?.removeAllObjects()
                
                //清空方向
                self.resetAllCirclesDirect()
                
                //完成之后改变clean的狀態
                self.hasClean = true
            }
            
            
        }
        
    }
    
    // 雷同于OC 中 synchronized 所线程
    func synchronized(_ lock:AnyObject,block:() throws -> Void)  rethrows{
        objc_sync_enter(lock)
        defer{
            objc_sync_exit(lock)
        }
        try block()
    }
    
    //MARK:- 获取当前选中圆的狀態
    func getCircleState() -> CircleState {
        return (self.circleSet?.firstObject as! GYCircle).state!
    }
    
    //MARK: - 清空所有子控件的方向
    func resetAllCirclesDirect() {
        
        (subviews as NSArray).enumerateObjects({ (obj, idx, stop) in
            (obj as! GYCircle).angle = 0
        })
    }
    
    //MARK:- 对数组最后一个对象的处理
    func circleSetLastObjectWithState(_ state: CircleState) {
        guard (self.circleSet?.lastObject != nil)  else {
            return
        }
        (self.circleSet?.lastObject as! GYCircle).state = state
    }
    
    //MARK: - 解锁类型: 设置 手势路径处理
    func gestureEndByTypeSettingWithGesture(_ gesture: NSString,length: CGFloat) {
        
        if Int(length) < CircleSetCountLeast {
            //连接少于最少个数(默认4个)
            
            //1.通知代理
            self.delegate?.circleViewConnectCirclesLessThanNeedWithGesture(self, type: self.type!, gesture: gesture as String)
            
            //2.改变狀態为error
            changeCircleInCircleSetWithState(CircleState.circleStateError)
        } else { //>= 4个
            
            let gestureOne = GYCircleConst.getGestureWithKey(gestureOneSaveKey)
            
            if gestureOne == nil {//未输入过少于4的手势
                // 记录第一次密码
                GYCircleConst.saveGesture(gesture as String, key: gestureOneSaveKey)
                
                self.delegate?.circleViewdidCompleteSetFirstGesture(self, type: self.type!, gesture:gesture as String )
            } else if  (gestureOne! as NSString).length < CircleSetCountLeast {
                // 记录第一次密码
                GYCircleConst.saveGesture(gesture as String, key: gestureOneSaveKey)
                
                self.delegate?.circleViewdidCompleteSetFirstGesture(self, type: self.type!, gesture:gesture as String )
            } else { //接收第二个密码并与第一个密码匹配，一致后存储起来
                let equal = gesture.isEqual(GYCircleConst.getGestureWithKey(gestureOneSaveKey)) //匹配两次手势
                
                //通知代理
                self.delegate?.circleViewdidCompleteSetSecondGesture(self, type: self.type!, gesture: gesture as String, result: equal)
                
                if equal {
                    // 一致，存储密码
                    GYCircleConst.saveGesture(gesture as String, key: gestureFinalSaveKey)
                } else {
                    //不一致 重绘回显
                    changeCircleInCircleSetWithState(CircleState.circleStateError)
                }
            }
            
        }
        
    }
    
    //MARK: - 解锁类型:登陆  手势路径的处理
    func gestureEndByTypeLoginWithGesture(_ gesture: NSString, length:CGFloat) {
        
        let password = GYCircleConst.getGestureWithKey(gestureFinalSaveKey)! as NSString
        
        let  equal = gesture.isEqual(password)
        
        self.delegate?.circleViewdidCompleteLoginGesture(self, type: self.type!, gesture: gesture as String, result: equal)
        
        if equal {
            
        } else {
            self.changeCircleInCircleSetWithState(CircleState.circleStateError)
        }
        
        
        
    }
    
    //MARK: - 解锁类型:验证 手势路径的处理
    func gestureEndByTypeVerifyWithGesture(_ gesture: NSString,length: CGFloat) {
        
        gestureEndByTypeLoginWithGesture(gesture, length: CGFloat(length))
        
    }
    
    
    
    //MARK: - 改变选中数组CircleSet子控件狀態
    func changeCircleInCircleSetWithState(_ state: CircleState) {
        
        self.circleSet?.enumerateObjects({ (circle, idx, stop) in
            
            let circleTy = circle as! GYCircle
            
            circleTy.state = state
            
            // 如果是错误狀態，那就将最后一个按钮特殊处理
            if state == CircleState.circleStateError {
                if idx == (self.circleSet?.count)! - 1 {
                    circleTy.state = CircleState.circleStateLastOneError
                }
            }
            
        })
        
        setNeedsDisplay()
        
    }
    
    //MARK:- 每添加一个圆，就计算一次方向
    func calAngleAndconnectTheJumpedCircle() {
        
        if circleSet == nil || circleSet?.count <= 1 {
            return
        }
        
        //取出最后一个对象
        let lastOne = circleSet?.lastObject as! GYCircle
        
        //倒数第二个
        let lastTwo = circleSet?.object(at: self.circleSet!.count - 2) as! GYCircle
        
        //计算倒数第二个的位置
        let last_1_x = lastOne.center.x
        let last_1_y = lastOne.center.y
        
        let last_2_x = lastTwo.center.x
        let last_2_y = lastTwo.center.y
        
        //1.计算角度（反正切函数）
        let angle = atan2(Float(last_1_y) - Float(last_2_y), Float(last_1_x) - Float(last_2_x)) + Float(Double.pi/2)
        lastTwo.angle = CGFloat(angle)
        //2.处理跳跃连线
        let center = centerPointWithPointOneandTwo(lastOne.center, pointTwo: lastTwo.center)
        
        let centerCircle = self.enumCircleSetToFindWhichSubviewContainTheCenterPoint(center)
        
        if centerCircle != nil {
            //把跳过的圆加到数组中，他的位置是倒数第二个
            if !(self.circleSet!.contains(centerCircle!)) {
                //插入数组中
                self.circleSet?.insert(centerCircle!, at: (self.circleSet?.count)! - 1)
                //指定此圆的角度与上一个角度相同。否则会造成移位
                centerCircle?.angle = lastTwo.angle
                
            }
        }
        
    }
    
    //提供两个点，返回一个中心点
    func centerPointWithPointOneandTwo(_ pointOne: CGPoint,pointTwo: CGPoint) -> CGPoint
    {
        let x1 = pointOne.x > pointTwo.x ? pointOne.x : pointTwo.x
        let x2 = pointOne.x < pointTwo.x ? pointOne.x : pointTwo.x
        let y1 = pointOne.y > pointTwo.y ? pointOne.y : pointTwo.y
        let y2 = pointOne.y < pointTwo.y ? pointOne.y : pointTwo.y
        
        return CGPoint(x: (x1 + x2)/2, y: (y1 + y2)/2)
        
        
    }
    //MARK:- 给一个点，判断这个点是否被圆包含，如果包含就返回当前圆，如果不包含返回的是nil
    /**
     判断两个点之间的中心点是否在圆上
     
     - parameter point: z中心点坐标
     
     - returns: 在就返回这个圆 不在返回nil
     */
    func enumCircleSetToFindWhichSubviewContainTheCenterPoint(_ point: CGPoint) ->  GYCircle? {
        
        var centerCircle: GYCircle?
        
        for circle: GYCircle in subviews as! [GYCircle] {
            if circle.frame.contains(point) {
                centerCircle = circle
            }
        }
        
        guard centerCircle != nil else {
            return nil
        }
        
        if !(self.circleSet?.contains(centerCircle!))! {
            //这个circle的角度和倒数第二个circle角度一致
            
            centerCircle?.angle = (self.circleSet?.object(at: (self.circleSet?.count)! - 2) as AnyObject).angle
        }
        guard (centerCircle != nil) else {
            DLog("此点不在圆内")
            return nil
        }
        return centerCircle!
    }
    
    
    //MARK: - 将circleSet数组解析遍历，拼手势密码字符串
    func getGestureResultFromCircleSet(_ circleSet: NSMutableArray) -> NSString {
        
        let gesture = NSMutableString.init()
        let circleSetArr = NSArray.init(array: circleSet)
        for circle: GYCircle in circleSetArr as! [GYCircle] {
            //遍历取tag拼接字符串 作为密码标识符
            DLog(circleSetArr.count)
            gesture.append(String(circle.tag))
        }
        
        return gesture
        
    }
    
}
