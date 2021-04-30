

import UIKit

@objc public protocol CLNavigationControllerProtocol : NSObjectProtocol {
    //页面是否有push的Action
    @objc optional func navigationControllerShouldPush(_ vc: CLNavigationController) -> Bool
    
    //页面执行push的Action，返回true，会在End触发rootView的End回调事件（暂时为了业务需求，后期寻找优化方案）
    @objc optional func navigationControllerDidPushBegin(_ vc: CLNavigationController) -> Bool
    //只执行rootView
    @objc optional func navigationControllerDidPushEnd(_ vc: CLNavigationController)
    
    //页面是否支持手势push
    func doNavigationControllerGesturePush(_ vc: CLNavigationController) -> Bool
    
    @objc optional func doNavigationControllerGesturePop(_ vc: CLNavigationController) -> Bool
    
    //可实现，判断 touch 接收者是否冲突，如 UISlider 等具有手势的控件，返回 false 则不触发 pop，反之触发
    @objc optional func doNavigationControllerGestureShouldPop(_ vc: CLNavigationController, receive touch: UITouch) -> Bool
}

public class CLNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    var currentShowVC: UIViewController?
    
    lazy var transition = CLNavigationControllerTransition()
    var pan: UIPanGestureRecognizer?
    
    var bResetScrollEable = false
    
    //TODO: 暂时使用其他push动画时，禁止手势pop
    var otherTransition: CLNavigationOtherTransition?
    
    var isPushingFansListVC: Bool = false   ///是否在push到粉絲列表

    override public func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarHidden(true, animated: false)
        self.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.delegate = self
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open var shouldAutorotate: Bool {
        if let b = viewControllers.last?.shouldAutorotate {
            return b
        }
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (viewControllers.last?.supportedInterfaceOrientations)!
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return (viewControllers.last?.preferredInterfaceOrientationForPresentation)!
    }
    
    override open var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
    
    //MARK: Public
    
    public func addGesturePush() {
//        edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(CLNavigationController.gestureDidPushed(_:)))
//        edgePan?.edges = .right
//        edgePan?.delegate = self
//        self.view.addGestureRecognizer(edgePan!)
        
        if pan == nil {
            pan = UIPanGestureRecognizer(target: self, action: #selector(CLNavigationController.gestureDidPushed(_:)))
            pan?.delegate = self
            self.view.addGestureRecognizer(pan!)
        }
    }
    
    public func changeTransition(_ bChange: Bool) {
        if bChange == true {
            if otherTransition == nil {
                otherTransition = CLNavigationOtherTransition()
            }
            self.delegate = otherTransition
        }
        else {
            self.delegate = self
        }
    }
    
    //MARK: UINavigationControllerDelegate
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
//        if viewController.isMember(of: FansListController.self) {
//            self.isPushingFansListVC = !self.isPushingFansListVC   ///处理push粉絲列表两次的问题
//            if self.isPushingFansListVC {
//                return
//            }
//        }
        
        if navigationController.viewControllers.count == 1 {
            self.currentShowVC = nil
        }
        else if animated {
            self.currentShowVC = viewController
        }
        else {
            self.currentShowVC = nil
        }
    }
    
    //MARK: UIGestureRecognizerDelegate
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if self.topViewController is CLNavigationControllerProtocol {
            let v = self.topViewController as! CLNavigationControllerProtocol
            if (v.doNavigationControllerGestureShouldPop) != nil {
                let bEnble = v.doNavigationControllerGestureShouldPop!(self, receive: touch)
                return bEnble
            }
        }
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.interactivePopGestureRecognizer {
            if let _ = otherTransition {
                if self.delegate is CLNavigationOtherTransition {
                    return false
                }
            }
            if self.topViewController is CLNavigationControllerProtocol {
                let v = self.topViewController as! CLNavigationControllerProtocol
                if (v.doNavigationControllerGesturePop) != nil {
                    let bEnble = v.doNavigationControllerGesturePop!(self)
                    return bEnble
                }
            }
            
            let bGesture = self.currentShowVC == self.topViewController
            return bGesture
        }
//        else if gestureRecognizer == edgePan {
//            if self.topViewController is CLRootScrollViewController {
//                let vc = self.topViewController as! CLRootScrollViewController
//                vc.mainScrollV.isScrollEnabled = false
//                gestureRecognizer.addTarget(transition, action: #selector(CLNavigationControllerTransition.gestureDidPushed(_:)))
//                return true
//            }
//            return false
//        }
        else if gestureRecognizer == pan {
            var bEnble = false
            //判断是否打开手势push
            if self.topViewController is CLNavigationControllerProtocol {
                let v = self.topViewController as! CLNavigationControllerProtocol
                bEnble = v.doNavigationControllerGesturePush(self)
            }
            if bEnble == false {
                return false
            }
            //判断条件是否满足手势push
            let gesture = gestureRecognizer as! UIPanGestureRecognizer
            let translation = gesture.velocity(in: gesture.view)
            //条件：手势方向为：水平向左
            if translation.x < 0 && abs(translation.x) > abs(translation.y) {
                var bScrollBegin = false
                let vc = self.topViewController
                //判断是否包含有可运行手势push的Action
                if vc is CLNavigationControllerProtocol {
                    if (vc?.responds(to: #selector(CLNavigationControllerProtocol.navigationControllerShouldPush(_:))))! {
                        let v = vc as! CLNavigationControllerProtocol
                        bScrollBegin = v.navigationControllerShouldPush!(self)
                    }
                }
                if bScrollBegin == true {
                    gesture.addTarget(transition, action: #selector(CLNavigationControllerTransition.gestureDidPushed(_:)))
                }
                return bScrollBegin
            }
        }
        return false
    }
    
    //MARK: Action
    
    @objc func gestureDidPushed(_ gestureRecognizer: UIPanGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: self.view)
        let tapAreaY = screenHeight - 95 - (UIDevice.current.isiPhoneXSeriesDevices() ? 34 : 0)
        if touchPoint.y > tapAreaY { return }  // 底部进度条区域， 禁止测滑
        if gestureRecognizer.state == .began {
            let vc = self.topViewController
            if (vc?.responds(to: #selector(CLNavigationControllerProtocol.navigationControllerDidPushBegin(_:))))! {
                let v = vc as! CLNavigationControllerProtocol
                self.delegate = transition
                bResetScrollEable = v.navigationControllerDidPushBegin!(self)
            }
        }
        else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            self.delegate = self;
            if bResetScrollEable == true {
                
                let vc = self.viewControllers.first
                if (vc?.responds(to: #selector(CLNavigationControllerProtocol.navigationControllerDidPushEnd(_:))))! {
                    let v = vc as! CLNavigationControllerProtocol
                    v.navigationControllerDidPushEnd!(self)
                }
                
                bResetScrollEable = false
            }
            gestureRecognizer.removeTarget(transition, action: #selector(CLNavigationControllerTransition.gestureDidPushed(_:)))
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
           return false
       }
    
}
