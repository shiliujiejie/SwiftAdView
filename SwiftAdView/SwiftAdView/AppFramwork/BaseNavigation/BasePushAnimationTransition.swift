

import UIKit

class BasePushAnimationTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var transitionDuration: TimeInterval = 0.3
    
    let offSetWidth: CGFloat = 0
    
    let interlaceFactor = 0.3
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)
        let toVC = transitionContext.viewController(forKey: .to)
        let containerView = transitionContext.containerView
        
        containerView.addSubview(fromVC!.view)
        
        let toViewFrame = CGRect(x: fromVC!.view.frame.size.width - offSetWidth, y: 0, width: fromVC!.view.frame.size.width + offSetWidth, height: fromVC!.view.frame.size.height)
        toVC?.view.frame = toViewFrame
        containerView.addSubview((toVC?.view)!)
        
        UIView.animate(withDuration: transitionDuration, delay: 0, options: .curveEaseOut, animations: {
            var fromViewFrame = fromVC?.view.frame
            fromViewFrame?.origin.x = -(0.3 * UIScreen.main.bounds.size.width)
            fromVC?.view.frame = fromViewFrame!
            
            var toViewFrame = toVC?.view.frame
            toViewFrame?.origin.x = self.offSetWidth
            toVC?.view.frame = toViewFrame!
        }) { (bFinish) in
            toVC?.view.frame = UIScreen.main.bounds
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    

}
