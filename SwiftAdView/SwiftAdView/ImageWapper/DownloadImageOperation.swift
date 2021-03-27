//
//  DownloadImageOperation.swift
//  SwiftAdView
//
//  Created by shiliu on 27/3/2021.
//  Copyright © 2021 AnakinChen Network Technology. All rights reserved.
//

import UIKit

class DownloadImageOperation: Operation {
    //下载图像的url
    private var URLString: String?
    //回调block
    private var finishBlock: ((_ image: Data) -> Void)?
    
    class func downloadImage(urlString: String, finish: @escaping ((_ image: Data) -> Void)) -> DownloadImageOperation {
        let op = DownloadImageOperation()
        op.URLString = urlString
        op.finishBlock = finish
        print("网络下载")
        return op
    }
    
    override func main() {
        autoreleasepool { () -> () in
            assert(URLString != nil, "图像的地址不能为空")
            assert(finishBlock != nil, "必须传入回调")
            guard let url = URL(string: URLString!) else { return }
            let data = try? Data(contentsOf: url)
            if data == nil {
                print("图片下载失败,请检查您的url地址是否正确")
                return
            }
            /// 图片解密操作， 然后存入
            try! data!.write(to: DownloadImageExtensions.imageFilesPath(url), options: .atomic)
            //判断操作是否被取消
            if self.isCancelled {
                print("操作被取消", url)
                return
            }
            //主线程回调
            OperationQueue.main.addOperation {
                if self.finishBlock != nil {
                    self.finishBlock!(data!)
                }
            }
        }
    }
}
