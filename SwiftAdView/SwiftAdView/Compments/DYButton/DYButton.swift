

import UIKit

/// 仿抖音点桃心按钮
class DYButton: UIButton {
    public enum DYButtonState {
        case cancel
        case selected
    }
    
    lazy fileprivate var hollowHeartLayer: CAShapeLayer = {
        let shaperLayer = configurationHeartLayer()
        shaperLayer.fillColor = UIColor.clear.cgColor
        return shaperLayer
    }()
    lazy fileprivate var redHeartLayer: CAShapeLayer = {
        let shaperLayer = configurationHeartLayer()
        shaperLayer.fillColor = UIColor(red: 255/255.0, green: 42/255.0, blue: 49/255.0, alpha: 1.0).cgColor
        shaperLayer.isHidden = true
        return shaperLayer
    }()
    
    fileprivate var isAnimating = false
    fileprivate var isShowRedHeart = false
    fileprivate var animationLayers = [CALayer]()
    
    public var dyState = DYButtonState.cancel {
        willSet {
            isAnimating = true
            switch newValue {
            case .cancel:
                unselected()
            case .selected:
                selected()
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isAnimating { return }
            isUserInteractionEnabled = false
            dyState = dyState == .cancel ? .selected : .cancel
        }
    }
    
    var animationDuration = 1.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configuration()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configuration()
    }
    
    fileprivate func configuration() {
        layer.addSublayer(hollowHeartLayer)
        layer.addSublayer(redHeartLayer)
        configurationMaskLayer()
    }
    
    fileprivate func configurationMaskLayer() {
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    cornerRadius: frame.width / 2)
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
    
    //画爱心
    fileprivate func configurationHeartLayer() -> CAShapeLayer {
        let rect = CGRect(x: 5, y: 5, width: frame.width - 10, height: frame.height - 10)
        let padding: CGFloat = 4
        let radius = (rect.size.width - 2 * padding) / 2.0 / (cos(CGFloat.pi / 4) + 1)
        
        let heartPath = UIBezierPath()
        
        //左圆的圆心
        let leftCurveCenter = CGPoint(x: padding + radius, y: rect.size.height / 2.8)
        //画左圆
        heartPath.addArc(withCenter: leftCurveCenter, radius: radius,
                         startAngle: CGFloat.pi, endAngle: CGFloat.pi * -0.25,
                         clockwise: true)
        
        //右圆圆心
        let rightCurveCenter = CGPoint(x: rect.width - padding - radius, y: leftCurveCenter.y)
        //画右圆
        heartPath.addArc(withCenter: rightCurveCenter, radius: radius,
                         startAngle: CGFloat.pi * -0.75, endAngle: 0,
                         clockwise: true)
        
        //爱心尖的坐标点
        let apexPoint = CGPoint(x: rect.width / 2, y: rect.height - padding)
        //画右半边曲线
        heartPath.addQuadCurve(to: apexPoint,
                               controlPoint: CGPoint(x: heartPath.currentPoint.x,
                                                     y: radius + rect.size.height / 2.8))
        
        //画左半边曲线
        heartPath.addQuadCurve(to: CGPoint(x: padding, y: leftCurveCenter.y),
                               controlPoint: CGPoint(x: padding,
                                                     y: radius + rect.size.height / 2.8))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = heartPath.cgPath
        shapeLayer.frame = rect
        return shapeLayer
    }
    
    //爱心出现动画
    fileprivate lazy var heartAppearAnimation: CAAnimationGroup = {
        let animation = CABasicAnimation.init(keyPath: "transform.scale")
        animation.duration = animationDuration * 0.8
        animation.fromValue = 0.1
        animation.toValue = 1
        
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.rotation.z")
        keyAnimation.values = [CGFloat.pi * -0.25, 0, CGFloat.pi * 0.1, CGFloat.pi * -0.05, 0]
        keyAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        keyAnimation.duration = animationDuration
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = animationDuration
        groupAnimation.delegate = self
        groupAnimation.animations = [keyAnimation, animation]
        return groupAnimation
    }()
    
    //爱心消失动画
    fileprivate lazy var heartDisappearAnimation: CAAnimationGroup = {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = animationDuration
        animation.fromValue = 1
        animation.toValue = 0
        
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.rotation.z")
        keyAnimation.values = [0, CGFloat.pi * -0.25]
        keyAnimation.fillMode = .forwards
        keyAnimation.duration = animationDuration * 0.4
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = animationDuration
        groupAnimation.delegate = self
        groupAnimation.animations = [keyAnimation, animation]
        groupAnimation.fillMode = .forwards
        groupAnimation.isRemovedOnCompletion = false
        redHeartLayer.add(groupAnimation, forKey: nil)
        return groupAnimation
    }()
    
    
    //画六条扇形
    fileprivate func configurationFanLayer() {
        let fanCenter = CGPoint(x: frame.width / 2, y: frame.height / 2)
        for i in 0..<6 {
            let path = UIBezierPath()
            path.addArc(withCenter: fanCenter,
                        radius: frame.width / 2,
                        startAngle: CGFloat.pi / 2 + (CGFloat.pi / 3) * CGFloat(i) - (CGFloat.pi / 72),
                        endAngle: CGFloat.pi / 2 + CGFloat.pi / 3 * CGFloat(i) + CGFloat.pi / 72,
                        clockwise: true)
            path.addLine(to: fanCenter)
            path.close()
            
            let fanLayer = CAShapeLayer()
            fanLayer.path = path.cgPath
            fanLayer.fillColor = UIColor.red.cgColor
            fanLayer.frame = bounds
            
            animationLayers.append(fanLayer)
            layer.addSublayer(fanLayer)
            
            //配置扩散动画
            let lineAnimation = addFanAnimation(destination: path.currentPoint)
            fanLayer.add(lineAnimation, forKey: nil)
        }
    }
    
    //扩散动画
    fileprivate func addFanAnimation(destination: CGPoint) -> CAAnimation {
        let fanAnimation = CABasicAnimation(keyPath: "position")
        fanAnimation.duration = animationDuration
        fanAnimation.fromValue = CGPoint(x: frame.width / 2, y: frame.height / 2)
        fanAnimation.toValue = destination
        fanAnimation.isRemovedOnCompletion = false
        fanAnimation.fillMode = .both
        return fanAnimation
    }
    
    fileprivate func selected() {
        redHeartLayer.isHidden = false
        hollowHeartLayer.isHidden = true
        isShowRedHeart = true
        redHeartLayer.add(heartAppearAnimation, forKey: nil)
        configurationFanLayer()
        setImage(UIImage(named: ""), for: .normal)
    }
    
    fileprivate func unselected() {
        hollowHeartLayer.isHidden = false
        isShowRedHeart = false
        redHeartLayer.add(heartDisappearAnimation, forKey: nil)
        setImage(UIImage(named: "icon_home_like_before"), for: .normal)
    }
    
    fileprivate func clean() {
        redHeartLayer.isHidden = !isShowRedHeart
        redHeartLayer.removeAllAnimations()
        isAnimating = false
        isUserInteractionEnabled = true
        for animationLayer in animationLayers {
            animationLayer.removeFromSuperlayer()
            animationLayer.removeAllAnimations()
        }
        animationLayers.removeAll()
    }
}

extension DYButton: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        clean()
    }
}
