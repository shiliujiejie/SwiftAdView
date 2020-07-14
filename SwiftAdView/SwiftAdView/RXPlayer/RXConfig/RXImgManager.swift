
import UIKit

class RXImgManager: UIView {
    class func foundImage(imageName:String) -> UIImage? {
//        let bundleB  = Bundle(for: self.classForCoder()) //先找到最外层Bundle
//        guard let resrouseURL = bundleB.url(forResource: "RXPlayer", withExtension: "bundle") else { return nil }
//        let bundle = Bundle(url: resrouseURL) // 根据URL找到自己的Bundle
//        return UIImage(named: imageName, in: bundle , compatibleWith: nil) //在自己的Bundle中找图片
        return UIImage(named: imageName)
    }
    
}
public struct  RXVideoModel {
    public var videoName: String?
    public var videoUrl: String?
    public var videoPlaySinceTime: Float = 0
}

public extension UIDevice {
    func isiPhoneXSeriesDevices() -> Bool {
        return (UIScreen.main.bounds.size.height >= 812.0 && UIDevice.current.model == "iPhone")
    }
}
