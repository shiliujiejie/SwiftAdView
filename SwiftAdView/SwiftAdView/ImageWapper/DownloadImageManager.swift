//
//  DownloadImageManager.swift
//  SwiftAdView
//
//  Created by shiliu on 27/3/2021.
//  Copyright © 2021 AnakinChen Network Technology. All rights reserved.
//

import UIKit

class DownloadImageManager: NSObject {
    //操作缓存池
    var operationCache = [String: Operation]()
    //图片缓存池
    var imageCache = [String: Data]()
    
    let queue = OperationQueue()
    
    //单例
    static let instance = DownloadImageManager()
    class func sharedManager() -> DownloadImageManager {
        return instance
    }
    
    func downloadImage(urlString: String, finishBlock: @escaping((_ image: Data?) -> Void)) {
        //判断缓存池中有没有
        if operationCache[urlString] != nil {
            print("正在下载中...稍安勿躁...")
            return
        }
        //判断沙盒里有没有图像
        if checkImageCache(urlString: urlString) {
            finishBlock(imageCache[urlString])
            return
        }
        //定义操作
        let op = DownloadImageOperation.downloadImage(urlString: urlString) { (image) in
            finishBlock(image)
            //移除操作
            self.operationCache.removeValue(forKey: urlString)
        }
        //把操作添加到缓存池
        operationCache.updateValue(op, forKey: urlString)
        //添加到队列
        queue.addOperation(op)
    }
    
    func cancelDownload(urlString: String?) {
        if urlString == nil {
            print("当前没有下载操作")
            return
        }
        //判断缓存池中有没有
        //有
        if let op = operationCache[urlString!] {
            print("取消下载---")
            op.cancel()
            //从缓存池中移除
            operationCache.removeValue(forKey: urlString!)
        }
    }
    
    func checkImageCache(urlString: String) -> Bool {
        //检查内存缓存
        if imageCache[urlString] != nil {
            print("从 内存缓存读取")
            return true
        }
        if let dataImg = try? Data(contentsOf: DownloadImageExtensions.imageFilesPath(URL(string: urlString)!)) {
            print("从沙盒缓存 -- 加载到内存 gif")
            imageCache[urlString] = dataImg
            return true
        }
        return false
    }
}
