

import UIKit

class CLNavigationControllerTransition: NSObject, UINavigationControllerDelegate {

    let kCLNavigationControllerTransitionBorderlineDelta = 0.3
    
    var _interactivePopTransition: UIPercentDrivenInteractiveTransition?
    var interactivePopTransition: UIPercentDrivenInteractiveTransition {
        get {
            if _interactivePopTransition == nil {
                _interactivePopTransition = UIPercentDrivenInteractiveTransition()
                _interactivePopTransition?.completionCurve = .easeOut
            }
            return _interactivePopTransition!
        }
    }
    
    lazy var pushAnimTransition = BasePushAnimationTransition()
    
    @objc func gestureDidPushed(_ gestureRecognizer: UIPanGestureRecognizer) {
        var progress = (gestureRecognizer.translation(in: gestureRecognizer.view)).x / (gestureRecognizer.view?.bounds.size.width)!
        
        if gestureRecognizer.state == .began {
            
            self.interactivePopTransition.update(0)
        }
        else if gestureRecognizer.state == .changed {
            if progress <= 0 {
                progress = abs(progress)
                progress = min(1.0, max(0.0, progress))
            }
            else {
                progress = 0
            }
            
            self.interactivePopTransition .update(progress)
        }
        else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            if abs(progress) > 0.3 {
                self.interactivePopTransition.finish()
            }
            else {
                self.interactivePopTransition.cancel()
            }
        }
    }
    
    //MARK: UINavigationControllerDelegate
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return pushAnimTransition
        }
        return nil
    }
    
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactivePopTransition
    }
}
