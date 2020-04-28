//
//  NicooImgManager.swift
//  NicooPlayer
//
//  Created by 小星星 on 2018/6/19.
//

import UIKit

class NicooImgManager: UIView {
    class func foundImage(imageName:String) -> UIImage? {
        let bundleB  = Bundle(for: self.classForCoder()) //先找到最外层Bundle
        guard let resrouseURL = bundleB.url(forResource: "NicooPlayer", withExtension: "bundle") else { return nil }
        let bundle = Bundle(url: resrouseURL) // 根据URL找到自己的Bundle
        return UIImage(named: imageName, in: bundle , compatibleWith: nil) //在自己的Bundle中找图片
    }
    
}
public struct  NicooVideoModel {
    public var videoName: String?
    public var videoUrl: String?
    public var videoPlaySinceTime: Float = 0
}

public extension UIDevice {
    
    /// 判断是否为X系列
    ///
    /// - Returns: 兼容X系列手机
    public func isiPhoneXSeriesDevices() -> Bool {
        return (iosType() == "iPhoneX" || iosType() == "iPhoneXS" || iosType() == "iPhoneXSMax" || iosType() == "iPhoneXR")
    }
    /// 判断是否为iPhoneX
    ///
    /// - Returns: 兼容
    public func isiPhoneX() -> Bool {
        return iosType() == "iPhoneX"
    }
    /// 判断是否为5S
    ///
    /// - Returns: 兼容
    public func isiPhone5S() -> Bool {
        return iosType() == "iPhone5S"
    }
    /// 判断是否为6P
    ///
    /// - Returns: 兼容
    public func isiPhone6Plus() -> Bool {
        return iosType() == "iPhone6Plus"
    }
    /// 判断是否为6
    ///
    /// - Returns: 兼容
    public func isiPhone6() -> Bool {
        return iosType() == "iPhone6"
    }
    /// 判断是否为6S
    ///
    /// - Returns: 兼容
    public func isiPhone6s() -> Bool {
        return iosType() == "iPhone6S"
    }
    /// 判断是否为6SP
    ///
    /// - Returns: 兼容
    public func isiPhone6SPlus() -> Bool {
        return iosType() == "iPhone6SPlus"
    }
    /// 判断是否为SE
    ///
    /// - Returns: 兼容
    public func isiPhoneSE() -> Bool {
        return iosType() == "iPhoneSE"
    }
    /// 判断是否为 模拟器(模拟器不区分型号)
    ///
    /// - Returns: 兼容
    public func isSimulator() -> Bool {
        return iosType() == "Simulator"
    }
    /// 判断是否为7
    ///
    /// - Returns: 兼容
    public func isiPhone7() -> Bool {
        return iosType() == "iPhone7"
    }
    /// 判断是否为7P
    ///
    /// - Returns: 兼容
    public func isiPhone7Plus() -> Bool {
        return iosType() == "iPhone7Plus"
    }
    func iosType() -> String {
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
        if platform == "i386"   { return "Simulator"}
        if platform == "x86_64" { return "Simulator"}
        return platform
    }
    /// 兼容iPad
    ///
    /// - Returns: 判断是否为iPad
    public func isPad() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }
}
