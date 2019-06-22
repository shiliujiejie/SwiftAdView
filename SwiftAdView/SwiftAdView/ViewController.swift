//
//  ViewController.swift
//  SwiftAdView
//
//  Created by mac on 2019/6/20.
//  Copyright © 2019年 mac. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let lauchScreen: UIImageView = {
        let imagev = UIImageView(image: UIImage(named: "guide02"))
        imagev.contentMode = .scaleAspectFill
        imagev.isUserInteractionEnabled = true
        return imagev
    }()
    
    var isShow: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(lauchScreen)
        lauchScreen.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isShow {
            loadADView()
        }
    }
    
    /*--->  广告逻辑: 一般来说，考虑网络问题，广告最好是走本地文件，但是需求一般都要可 后台 配置.
     
     基本逻辑:
     一. 第一次下载App,进入，（1）：没有广告（新手奖励之类的弹框，或者引导页替代广告） （2）：加载代码中默认的广告图，广告视频。
     二. 进入App后，后台下载后台配置的广告，保存到沙盒中。
     三. 用户下次进入App,直接读取 上次下载到 沙盒中 的广告文件，展示。
     
     <---*/
    func loadADView() {
        if let currentAd = SwiftAdFileConfig.readCurrentAdModel() { // 1. 检测 本地 有没有 广告
            showAdVC(currentAd)
        } else {
            showDefaultAd()  // 2. 本地没找到对应的广告文件，展示默认广告
        }
        // 3. 检测服务器是否 换了新广告
        loadAdAPI()
    }

    /// 展示默认 广告， 或者不展示广告
    func showDefaultAd() {
        /// image
       // let fileImage = Bundle.main.path(forResource: "guide02", ofType: "png") ?? ""
        /// gif
        let fileGif = Bundle.main.path(forResource: "foldingcell", ofType: "gif") ?? ""
        /// 视频
       // let fileVideo = Bundle.main.path(forResource: "1", ofType: "mp4") ?? ""
        
        let admodel = AdFileModel(adUrl: fileGif, adType: .gif, adHerfUrl: "http://www.baidu.com", adId: 1)
        
        showAdVC(admodel)
       
    }
    
    func showAdVC(_ ad: AdFileModel) {
        
        let config = SwiftAdFileConfig()
        config.duration = 10
        config.autoDissMiss = false
        config.videoGravity = .resizeAspectFill
    
        let advc = SwiftAdView(config: config, adModel: ad)
        self.present(advc, animated: false, completion: nil)
        self.isShow = true
        advc.skipBtnClickHandler = {
            
        }
    }
   
}


// MARK: - 模拟 请求广告数据， 下载
extension ViewController {
    
    /// 这里模拟网络请求到 广告数据 后的操作
    func loadAdAPI() {
        
        // 模拟网络请求1.5秒
        self.sleep(1.5) {
            /// 请求结果 构造 model (根据了 链接对应的数据 的文件格式。确定 adType : "image"   "gif"  "video")
            // http://tb-video.bdstatic.com/tieba-smallvideo-transcode/3612804_e50cb68f52adb3c4c3f6135c0edcc7b0_3.mp4
            // https://github.com/shiliujiejie/adResource/raw/master/1.mp4
            // https://github.com/shiliujiejie/adResource/raw/master/2.mp4
            // https://github.com/shiliujiejie/adResource/raw/master/3.mp4
            // https://github.com/shiliujiejie/adResource/raw/master/folding-cell.gif
            // https://github.com/shiliujiejie/adResource/raw/master/maskp.gif
            // https://github.com/shiliujiejie/adResource/raw/master/timg.jpeg
            // http://cdn-hw.570920.com/video_ad/ao/7c/12ao7c3ee37f66d36b7f413a58d6483054aae59128.m3u8
            
            let admodel = AdFileModel.init(adUrl: "https://github.com/shiliujiejie/adResource/raw/master/1.mp4", adType: .video, adHerfUrl: "http://www.baidu.com", adId: 0)
            
            /// 下载广告, 下次启动展示
            SwiftAdFileConfig.downLoadAdData(admodel)
        }
    }
    
    /// 线程延时
    private func sleep(_ time: Double,mainCall:@escaping ()->()) {
        let time = DispatchTime.now() + .milliseconds(Int(time * 1000))
        DispatchQueue.main.asyncAfter(deadline: time) {
            mainCall()
        }
    }
}
