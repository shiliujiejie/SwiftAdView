//
//  DownloadImageExtensions.swift
//  SwiftAdView
//
//  Created by shiliu on 27/3/2021.
//  Copyright © 2021 AnakinChen Network Technology. All rights reserved.
//
import UIKit

class DownloadImageExtensions: NSObject {
    public static let downloadFile = "DYImageDownloads"
    
    open class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    /// 创建图片缓存文件夹
    open class func checkOrCreatedImageDirectory() {
        let filePath = getDocumentsDirectory().appendingPathComponent(downloadFile)
        if !FileManager.default.fileExists(atPath: filePath.path) {
            try? FileManager.default.createDirectory(at: filePath, withIntermediateDirectories: true, attributes: nil)
        }
    }
    /// 解密后的图片文件
    open class func imageFilesPath(_ urlString: URL) -> URL {
        checkOrCreatedImageDirectory()
        let filePath = getDocumentsDirectory().appendingPathComponent(downloadFile).appendingPathComponent("\(urlString.lastPathComponent.components(separatedBy: ".").first ?? urlString.absoluteString.md5()).data")
        NLog("filePath - \(filePath)")
        return filePath
    }
    /// 删除所有下载的图片文件
    open class func deleteAllDownloadedContents() {
        let filePath = getDocumentsDirectory().appendingPathComponent(downloadFile).path
        if FileManager.default.fileExists(atPath: filePath) {
            try? FileManager.default.removeItem(atPath: filePath)
        } else {
            NLog("File has already been deleted.")
        }
    }
}

extension UIImageView {
    private struct AssociatedKeys{
        static let kWebImageKey = "kWebImageKey"
    }
    //当前下载操作的URL
    //使用关联度细给分类加属性
    var currentURL : String? {
        get
        {
            return objc_getAssociatedObject(self, AssociatedKeys.kWebImageKey) as? String
        }
        
        set(newValue)
        {
            if let newValue = newValue
            {
                objc_setAssociatedObject(
                    self,
                    AssociatedKeys.kWebImageKey,
                    newValue as NSString?,
                    objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
            }
        }
    }
    ///  网络图片
    ///
    ///  - parameter urlString: 图片地址URL
    ///  - parameter placeHolder: 占位图
    func setImage(urlString: String, placeHolder: UIImage?) {
        self.image = placeHolder
        //1.判断是否有下载操作
        if let cuUrl = currentURL, !cuUrl.isEmpty  && (urlString != cuUrl) {
            DownloadImageManager.sharedManager().cancelDownload(urlString: currentURL)
            //清空图片
            self.image = placeHolder
        }
        //记录当前下载
        currentURL = urlString
        DownloadImageManager.sharedManager().downloadImage(urlString: urlString) { (imgData) -> Void in
            if imgData == nil {
                self.image = placeHolder
                return
            }
            let dataType = UIImage.checkImageDataType(data: imgData!)
            if dataType == .gif {
                self.image = UIImage.gif(data: imgData!)
            } else {
                self.image = UIImage(data: imgData!)
            }
        }
    }
}


extension UIButton {
    private struct AssociatedKeys{
        static let kWebImageKey = "kWebImageKey"
    }
    //当前下载操作的URL
    //使用关联度细给分类加属性
    var currentURL : String? {
        get
        {
            return objc_getAssociatedObject(self, AssociatedKeys.kWebImageKey) as? String
        }
        
        set(newValue)
        {
            if let newValue = newValue
            {
                objc_setAssociatedObject(
                    self,
                    AssociatedKeys.kWebImageKey,
                    newValue as NSString?,
                    objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
            }
        }
    }
    ///  设置 网络图片
    ///
    ///  - parameter urlString: 图片地址URL
    ///  - parameter placeHolder: 占位图
    func setImage(urlString: String, placeHolder: UIImage?) {
        self.setImage(placeHolder, for: .normal)
        //1.判断是否有下载操作
        if let cuUrl = currentURL, !cuUrl.isEmpty  && (urlString != cuUrl) {
            DownloadImageManager.sharedManager().cancelDownload(urlString: currentURL)
            //清空图片
            self.setImage(placeHolder, for: .normal)
        }
        //记录当前下载
        currentURL = urlString
        DownloadImageManager.sharedManager().downloadImage(urlString: urlString) { (imgData) -> Void in
            if imgData == nil {
                self.setImage(placeHolder, for: .normal)
                return
            }
            let dataType = UIImage.checkImageDataType(data: imgData!)
            if dataType == .gif {
                self.setImage(UIImage.gif(data: imgData!), for: .normal)
            } else {
                self.setImage(UIImage(data: imgData!), for: .normal)
            }
        }
    }
    ///  设置网络背景图片
    ///
    ///  - parameter urlString: 图片地址URL
    ///  - parameter placeHolder: 占位图
    func setBackgroundImage(urlString: String, placeHolder: UIImage?) {
        self.setImage(placeHolder, for: .normal)
        //1.判断是否有下载操作
        if let cuUrl = currentURL, !cuUrl.isEmpty  && (urlString != cuUrl) {
            DownloadImageManager.sharedManager().cancelDownload(urlString: currentURL)
            //清空图片
            self.setImage(placeHolder, for: .normal)
        }
        //记录当前下载
        currentURL = urlString
        DownloadImageManager.sharedManager().downloadImage(urlString: urlString) { (imgData) -> Void in
            if imgData == nil {
                self.setImage(placeHolder, for: .normal)
                return
            }
            let dataType = UIImage.checkImageDataType(data: imgData!)
            if dataType == .gif {
                self.setImage(UIImage.gif(data: imgData!), for: .normal)
            } else {
                self.setImage(UIImage(data: imgData!), for: .normal)
            }
        }
    }
}
