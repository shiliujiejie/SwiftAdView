
import UIKit
import Kingfisher
import AVKit
import Alamofire
import CommonCrypto



struct AdFileModel: Codable {
    var adUrl: String        // 广告路径
    var adType: AdFileType   //
    var adHerfUrl: String?
    var adId: Int = 0
    var customSaveKey: String? = nil  /// 自定义 模型 存储key
}

/// 广告文件类型
///
/// - gif: 动图
/// - image: 静态图
/// - video: 视频 目前支持 .mp4  （.m3u8 格式 不能走本地缓存） （其他格式未测试）
/// - defaultType: 默认类型
public enum AdFileType: String, Codable {
    case gif  = "gif"
    case image  = "image"
    case video  = "video"
    case defaultType
}


/// 广告基础设置
class SwiftAdFileConfig: NSObject {
    
    /// 时间倒数完,自动消失（非视频广告）
    var autoDissMiss: Bool = true
    /// 广告停留时间
    var duration: TimeInterval = 5.0
    /// 链接 跳safari 浏览器
    var openInSafari: Bool = true
    /// 跳过按钮背景色
    var skipBtnBackgroundColor: UIColor? = UIColor(white: 0.0, alpha: 0.5)
    /// 按钮文字颜色
    var skipBtnTitleColor: UIColor? = UIColor.white
    /// 文字字体
    var skipBtnFont: UIFont? = UIFont.systemFont(ofSize: 15)
    /// 视频填充模式
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill

}

// MARK: - 公共操作
extension SwiftAdFileConfig {
    
    /// 下载广告文件，保存本地
    class func downLoadAdData(_ adModel: AdFileModel) {
        if adModel.adType == .video {
            if let _ = SwiftAdFileConfig.getVideoFilePathFromLocal(adModel.adUrl) {
                print("这个广告已经下载过 --- video ")
                /// 下载过 也要存一次，因为ke能是 第二次上之前的广告
                saveAdModelWith(adModel)
            } else {
                /// 如果遇到视频 格式  .m3u8  则不要去下载， 直接存调用 （目前不支持 .m3u8本地缓存，如果是 .m3u8视频或者其他格式， 请直接存储model，下次会直接走网络链接）
                if adModel.adUrl.hasSuffix(".m3u8") {
                    saveAdModelWith(adModel)
                    return
                }
                downLoadVideoDataWith(adModel)
            }
        } else {
            if let _ = getAdDataFromLocal(adModel.adUrl) { // 这个广告已经下载过
                print("这个广告已经下载过 --- image or gif")
                /// 存入当前需要展示的广告
                saveAdModelWith(adModel)
            } else {
                downLoadImageDataWith(adModel)
            }
        }
    }
    
    /// 本地存储 广告 模型
    class func saveAdModelWith(_ adModel: AdFileModel) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let resultData = try? encoder.encode(adModel)
        UserDefaults.standard.set(resultData, forKey: adModel.customSaveKey ?? UserDefaults.kAdDataFileModel)
    }
    
    /// 获取当前需要展示的广告模型
    class func readCurrentAdModel(_ key: String? = nil) -> AdFileModel? {
        if let adData = UserDefaults.standard.value(forKey: key ?? UserDefaults.kAdDataFileModel) as? Data {
            // 解码
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let ad = try? decoder.decode(AdFileModel.self, from:adData)
            return ad
        }
        return nil
    }
    
    /// 删除本地所有缓存
    public class func clealAllLocalCache() -> Bool {
        guard let filePath = self.rootFilePath() else {
            return false
        }
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: filePath))
            } catch {
                print(error)
                return false
            }
        }
        return true
    }
    
    /// 根目录
    class func rootFilePath() -> String? {
        let docDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let filePath = (docDir as NSString).appendingPathComponent("LuanchAdDataSource")
        if !FileManager.default.fileExists(atPath: filePath) {
            do {
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
                return nil
            }
        }
        return filePath
    }
    
    
}

// MARK: - 本地广告 图片 操作
extension SwiftAdFileConfig {
    
    /// 下载并保存图片广告
    private class func downLoadImageDataWith(_ adModel: AdFileModel) {
        guard let url = URL(string: adModel.adUrl) else { return }
        ImageDownloader.default.downloadImage(with: url, retrieveImageTask: nil, options: nil, progressBlock: { (reciveData, allData) in
            print("Download Progress Image = \(Float64(reciveData)/Float64(allData))")
        }) { (image, error, imageUrl, adData) in
            if adData != nil {
                print("开屏图片广告下载成功。\(String(describing: adData))")
                if url.absoluteString.hasSuffix(".ceb") { /// 加密走这里
                    //                    if let data = adData as NSData? {
                    //                        if let dataDec = data.aes128DecryptWidthKey(ConstValue.kImageDataDecryptKey) as Data? {
                    //                            let _ = SwiftAdView.saveDataToLocal(url.absoluteString, data: dataDec)
                    //                            UserDefaults.standard.set(url.absoluteString, forKey: UserDefaults.kAdDataUrl)
                    //                        }
                    //                    }
                } else {
                    /// 存储广告文件到本地
                    let _ = SwiftAdFileConfig.saveDataToLocal(url.absoluteString, data: adData)
                    /// 存入当前需要展示的广告model
                    let dataType = UIImage.checkImageDataType(data: adData)
                    var newAdModel = adModel
                    if dataType == .gif {
                        newAdModel.adType = .gif
                    } else {
                        newAdModel.adType = .image
                    }
                    saveAdModelWith(adModel)
                }
            }
        }
    }
    
    /// 保存下载好的 '图片'  资源到本地沙盒
    class func saveDataToLocal(_ url: String, data: Data?) -> Bool {
        guard data != nil, let filePath = self.filePath(url) else {
            return false
        }
        let isSuccess = NSKeyedArchiver.archiveRootObject(data!, toFile: filePath)
        return isSuccess
    }
    
    /// 获取本地缓存 的 图片
    class func getAdDataFromLocal(_ url: String) -> Data? {
        guard let filePath = self.filePath(url) else {
            return nil
        }
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? Data
        return data
    }
    
    /// 获取本地缓存的  ’图片‘ 文件路径，没有则创建一个
    class func filePath(_ url: String) -> String? {
        guard let filePath = self.rootFilePath() else {
            return nil
        }
        print("rootFilePath: == \(filePath)")
        // 把资源路径通过MD5加密后，作为文件的名称进行保存
        return (filePath as NSString).appendingPathComponent(url.md5() + ".data")
    }
    
}

// MARK: - 本地缓存 视频 操作
extension SwiftAdFileConfig {
    
    /// 下载视频广告
    private class func downLoadVideoDataWith(_ adModel: AdFileModel) {
        guard let rootFilePath = self.rootFilePath() else { return }
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let videoPath = rootFilePath + "/\(adModel.adUrl.md5() + ".mp4")"
            let fileUrl = URL(fileURLWithPath: videoPath)
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        Alamofire.download(adModel.adUrl, to: destination)
            .downloadProgress { progress in
                print("Download AD Video: \(progress.fractionCompleted)")
            }
            .responseData { response in
                if let _ = response.result.value {
                    //let _ = SwiftAdFileConfig.saveVideoToLocal(adModel.adUrl, data: data)
                    /// 存入当前需要展示的广告模型
                   saveAdModelWith(adModel)
                }
        }
    }
    
    /// 保存下载好的 '视频'  资源到本地沙盒
    class func saveVideoToLocal(_ url: String, data: Data?) {
        if let videoData = data, let rootPath = rootFilePath() {
            let fileUrl = URL(fileURLWithPath: rootPath + "/\(url.md5() + ".mp4")")
            let _ = try? videoData.write(to: fileUrl)
        }
    }
    
    /// 获取本地缓存 的 视频 路径
    class func getVideoFilePathFromLocal(_ url: String) -> String? {
        guard let filePath = self.fileVideoPath(url) else {
            return nil
        }
        return filePath
    }
    
    /// 获取本地缓存的  ’视频‘ 文件路径，没有则创建一个
    class func fileVideoPath(_ url: String) -> String? {
        guard let filePath = self.rootFilePath() else {
            return nil
        }
        print("rootFileVideoPath: == \(filePath)")
        let fileUrl = filePath + "/\(url.md5() + ".mp4")"
        if FileManager.default.fileExists(atPath: fileUrl) {
            return fileUrl
        } else {
            return nil
        }
    }
    
}

extension String {
    func md5() -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        free(result)
        return String(format: hash as String)
    }
}

extension UserDefaults {
    /// 广告模型数据
    static let kAdDataFileModel = "AdDataFileModel"
}
