
import UIKit

/// 播放状态枚举
///
/// - Failed: 失败
/// - ReadyToPlay: 将要播放
/// - Unknown: 未知
/// - Buffering: 正在缓冲
/// - Playing: 播放
/// - Pause: 暂停
public enum PlayerStatus {
    case Failed
    case ReadyToPlay
    case Unknown
    case Buffering
    case Playing
    case Pause
}

class RXImgManager: UIView {
    class func foundImage(imageName:String) -> UIImage? {
//        let bundleB  = Bundle(for: self.classForCoder()) //先找到最外层Bundle
//        guard let resrouseURL = bundleB.url(forResource: "RXPlayer", withExtension: "bundle") else { return nil }
//        let bundle = Bundle(url: resrouseURL) // 根据URL找到自己的Bundle
//        return UIImage(named: imageName, in: bundle , compatibleWith: nil) //在自己的Bundle中找图片
        return UIImage(named: imageName)
    }
}
 
class RXDeviceModel {
    /// 判断是否为X系列
    ///
    /// - Returns: 兼容X系列手機
    class func isiPhoneXSeries() -> Bool {
        return (iosModel() == "iPhoneX" || iosModel() == "iPhoneXS" || iosModel() == "iPhoneXSMax" || iosModel() == "iPhoneXR" || iosModel().contains("iPhone11"))
    }
    /// 判断是否为 模拟器(模拟器不区分型号)
    ///
    /// - Returns: 兼容
    class func isSimulator() -> Bool {
        return iosModel() == "Simulator"
    }
    class func iosModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let platform = withUnsafePointer(to: &systemInfo.machine.0) { ptr in
            return String(cString: ptr)
        }
        if platform == "iPhone6,1" { return "iPhone5S"}
        if platform == "iPhone6,2" { return "iPhone5S"}
        if platform == "iPhone7,1" { return "iPhone6Plus"}
        if platform == "iPhone7,2" { return "iPhone6"}
        if platform == "iPhone8,1" { return "iPhone6S"}
        if platform == "iPhone8,2" { return "iPhone6SPlus"}
        if platform == "iPhone8,4" { return "iPhoneSE"}
        if platform == "iPhone9,1" { return "iPhone7"}
        if platform == "iPhone9,2" { return "iPhone7Plus"}
        if platform == "iPhone10,1" { return "iPhone8"}
        if platform == "iPhone10,2" { return "iPhone8Plus"}
        if platform == "iPhone10,3" { return "iPhoneX"}    // 国行
        if platform == "iPhone10,4" { return "iPhone8"}
        if platform == "iPhone10,5" { return "iPhone8Plus"}
        if platform == "iPhone10,6" { return "iPhoneX"}   // 美港
        if platform == "iPhone11,2" { return "iPhoneXS"}
        if platform == "iPhone11,4" { return "iPhoneXSMax"} // 国行
        if platform == "iPhone11,6" { return "iPhoneXSMax"} // 美港
        if platform == "iPhone11,8" { return "iPhoneXR"}
        if platform == "iPhone12,1" { return "iPhone11"}
        if platform == "iPhone12,3" { return "iPhone11Pro"}
        if platform == "iPhone12,5" { return "iPhone11ProMax"}
        if platform == "i386"   { return "Simulator"}
        if platform == "x86_64" { return "Simulator"}
        return platform
    }
}
