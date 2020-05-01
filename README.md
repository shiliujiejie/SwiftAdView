# SwiftAdView


  支持     图片   gif   视频   的启动广告     支持时间、样式、事件 自定义。

## | ScreenRecording  |

     图一 .  图片 广告
     图二 .  gif 广告
     图三 .  mp4 广告

|![Recording](https://github.com/shiliujiejie/adResource/raw/master/advertiseImage.gif) |![Recording](https://github.com/shiliujiejie/adResource/raw/master/advertiseGif.gif) | ![Recordings](https://github.com/shiliujiejie/adResource/raw/master/advertiseMP4.gif) | 

     

# 1.  加载 Bundle   资源：

        静态图片：
        
            /// .image
            let fileImage = Bundle.main.path(forResource: "guide02", ofType: "png") ?? ""

            let admodel = AdFileModel(adUrl: fileImage, adType: .image, adHerfUrl: "http://www.baidu.com", adId: 1)
            
        gif动图:  
        
            /// .gif
            let fileGif = Bundle.main.path(forResource: "foldingcell", ofType: "gif") ?? ""
             
            let admodel = AdFileModel(adUrl: fileGif, adType: .gif, adHerfUrl: "http://www.baidu.com", adId: 1)
    
            
        视频广告:
        
            /// .video
            let fileVideo = Bundle.main.path(forResource: "1", ofType: "mp4") ?? ""
            let admodel = AdFileModel(adUrl: fileVideo, adType: .video, adHerfUrl: "http://www.baidu.com", adId: 1)
  
  
  
  # 2. 后台配置广告  
  
    广告逻辑: 
     
    一般来说，考虑 网络加载速度 问题，广告最好是走本地文件，但是需求一般都要可 后台 配置.
    
    基本逻辑:
    
    一. 第一次下载App,进入，（1）：没有广告（新手奖励之类的弹框，或者引导页替代广告） （2）：加载 Bundle 中 默认的广告图，广告视频。
    
    二. 进入App后，请求广告Api，得到广告下载地址，后台下载广告文件，保存到沙盒中。（广告文件： 图片，gif,视频文件）
    
    三. 用户下次进入App,直接读取 上次下载到 沙盒中 的广告文件，展示。
    
       func loadADView() {
           // 1. 检测 本地 有没有 广告
           if let currentAd = SwiftAdFileConfig.readCurrentAdModel() { 
               showAdView(currentAd)
           } else {
           // 2. 本地没找到对应的广告文件，展示默认广告
               showDefaultAd()  
           }
           // 3. 检测服务器是否 换了新广告
           loadAdAPI()
       }
       
       服务器Api 请求成功后, 根据广告类型 构造 AdFileModel 对象，下载广告
       
       let admodel = AdFileModel.init(adUrl: "https://github.com/shiliujiejie/adResource/raw/master/1.mp4", adType: .video, adHerfUrl: "http://www.baidu.com", adId: 0)
       
       /// 下载广告, 下次启动展示
       SwiftAdFileConfig.downLoadAdData(admodel)
    

