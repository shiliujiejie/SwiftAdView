

import UIKit

class CLBaseTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var transitionDuration: TimeInterval = 0.3
    
    //MARK: UIViewControllerAnimatedTransitioning
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
    }
}


class CLNavigationOtherTransition: NSObject, UINavigationControllerDelegate {

    let kCLNavigationControllerTransitionBorderlineDelta = 0.3
    
    lazy var push = CLPresentPushTransition()
    
    lazy var pop = CLPresentPopTransition()
    
    //MARK: UINavigationControllerDelegate
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return push
        }
        else if operation == .pop {
            return pop
        }
        return nil
    }
}


class CLPresentPushTransition: CLBaseTransition {
    
    let offSetHeight: CGFloat = 0
    
    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)
        let toVC = transitionContext.viewController(forKey: .to)
        let containerView = transitionContext.containerView
        
        containerView.addSubview(fromVC!.view)
        
        let toViewFrame = CGRect(x: 0, y: fromVC!.view.frame.size.height - offSetHeight, width: fromVC!.view.frame.size.width, height: fromVC!.view.frame.size.height + offSetHeight)
        toVC?.view.frame = toViewFrame
        containerView.addSubview((toVC?.view)!)
        
        UIView.animate(withDuration: transitionDuration, delay: 0, options: .curveEaseOut, animations: {
            let fromViewFrame = fromVC?.view.frame
            toVC?.view.frame = fromViewFrame!
        }) { (bFinish) in
            toVC?.view.frame = (fromVC?.view.frame)!
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

}


class CLPresentPopTransition: CLBaseTransition {
    
    let offSetHeight: CGFloat = 0
    
    override func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)
        let toVC = transitionContext.viewController(forKey: .to)
        let containerView = transitionContext.containerView
        
        toVC?.view.frame = (fromVC?.view.frame)!
        containerView.addSubview((toVC?.view)!)
        
        containerView.addSubview(fromVC!.view)
        
        let toViewFrame = CGRect(x: 0, y: fromVC!.view.frame.size.height - offSetHeight, width: fromVC!.view.frame.size.width, height: fromVC!.view.frame.size.height + offSetHeight)
        UIView.animate(withDuration: transitionDuration, delay: 0, options: .curveEaseOut, animations: {
            fromVC?.view.frame = toViewFrame
        }) { (bFinish) in
            fromVC?.view.frame = toViewFrame
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

}

