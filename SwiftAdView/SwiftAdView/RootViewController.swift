
import UIKit

class RootViewController: UIViewController {
    
    private lazy var showAdBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("showAgain", for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(showAd), for: .touchUpInside)
        btn.frame = CGRect(x: 120, y: 250, width: 100, height: 40)
        return btn
    }()
    private lazy var showVideoBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("showVideo", for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(showVideoVC(_:)), for: .touchUpInside)
        btn.frame = CGRect(x: 120, y: 320, width: 100, height: 40)
        return btn
    }()
    
    private lazy var listVideoBtn: UIButton = {
          let btn = UIButton(type: .custom)
          btn.setTitle("listVideo", for: .normal)
          btn.backgroundColor = UIColor.gray
          btn.setTitleColor(UIColor.red, for: .normal)
          btn.addTarget(self, action: #selector(showVideoVC(_:)), for: .touchUpInside)
          btn.frame = CGRect(x: 120, y: 390, width: 100, height: 40)
          return btn
      }()
    private lazy var parserBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("下载", for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(parseM3u8(_:)), for: .touchUpInside)
        btn.frame = CGRect(x: 30, y: 450, width: 100, height: 40)
        return btn
    }()
    private lazy var pauseBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("pause", for: .normal)
        btn.setTitle("resume", for: .selected)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.addTarget(self, action: #selector(showVideoVC(_:)), for: .touchUpInside)
        btn.frame = CGRect(x: 150, y: 450, width: 70, height: 40)
        btn.isHidden = true
        return btn
    }()
    private let speedlab: UILabel = {
        let lab = UILabel()
        lab.frame = CGRect(x: 250, y: 450, width: 100, height: 40)
        return lab
    }()
    
    private lazy var localVideoBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("playLocal", for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(showVideoVC(_:)), for: .touchUpInside)
        btn.frame = CGRect(x: 120, y: 510, width: 100, height: 40)
        btn.isHidden = true
        return btn
    }()
    
    lazy var tsMger: TSManager = {
        let tsm = TSManager()
        tsm.delegate = self
        return tsm
    }()
    
    //"http://yun.kubo-zy-youku.com/20181112/BULbB7PC/index.m3u8"  // 非加密 2层 m3u8
    let videoUrl = "http://yun.kubo-zy-youku.com/20181112/BULbB7PC/index.m3u8"

    var isAdShow: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        self.title = "首页"
        view.addSubview(showAdBtn)
        view.addSubview(showVideoBtn)
        view.addSubview(listVideoBtn)
        view.addSubview(parserBtn)
        view.addSubview(pauseBtn)
        view.addSubview(speedlab)
        view.addSubview(localVideoBtn)
        loadADView()
        if DownLoadHelper.checkIsInterruptDownload(videoUrl.md5()) {
            parserBtn.setTitle("继续下载", for: .normal)
            parserBtn.tag = 99
        } else {
            parserBtn.setTitle("下载", for: .normal)
            parserBtn.tag = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if !isAdShow {
//            loadADView()
//        }
    }
    
    @objc func showAd() {
        loadADView()
    }
    
    @objc func showVideoVC(_ sender: UIButton) {
        if sender == showVideoBtn {
            let c = VideoPlayController()
            navigationController?.pushViewController(c, animated: true)
        } else if sender == listVideoBtn {
            let cc = VideoTableController()
            navigationController?.pushViewController(cc, animated: true)
        }
        if sender == localVideoBtn {
            let identifer = videoUrl.md5()
            if DownLoadHelper.filesIsExist(identifer) {
                let localPlayVC = DownLoadedVideoPlayerVC()
                localPlayVC.identifer = identifer
                navigationController?.pushViewController(localPlayVC, animated: true)
            }
        } else if sender == pauseBtn {
            if sender.isSelected {
                tsMger.resume()
                sender.isSelected = false
            } else {
                tsMger.pause()
                sender.isSelected = true
            }
        }
    }
    @objc func parseM3u8(_ sender: UIButton) {
        if DownLoadHelper.filesIsExist(videoUrl.md5()) {
            parserBtn.setTitle("已下载", for: .normal)
            speedlab.text = "已完成下载"
            localVideoBtn.isHidden = false
            return
        }
        sender.setTitle("解析中...", for: .normal)
        if sender.tag == 99 {
            tsMger.directoryName = videoUrl.md5()
            tsMger.m3u8URL = videoUrl
            tsMger.downloadFromLastInterruptedIndex()
            pauseBtn.isHidden = false
        } else {
            let filesExist = DownLoadHelper.filesIsExist(videoUrl.md5())
            if !filesExist {
                tsMger.directoryName = videoUrl.md5()
                tsMger.m3u8URL = videoUrl
                tsMger.download()
                pauseBtn.isHidden = false
            } else {
                print("当前视频已经下载了")
            }
        }
    }
    
}



// MARK: - 模拟 请求广告数据， 下载
extension RootViewController {
    func loadADView() {
        if let currentAd = SwiftAdFileConfig.readCurrentAdModel() { // 1. 检测 本地 有没有 广告
            showAdView(currentAd)
        } else {
            showDefaultAd()  // 2. 本地没找到对应的广告文件，展示默认广告
        }
        // 3. 检测服务器是否 换了新广告
        loadAdAPI()
    }
    
    /// 展示默认 广告， 或者不展示广告
    func showDefaultAd() {
        /// image
        //let fileImage = Bundle.main.path(forResource: "guide02", ofType: "png") ?? ""
        /// gif
        let fileGif = Bundle.main.path(forResource: "foldingcell", ofType: "gif") ?? ""
        /// 视频
        // let fileVideo = Bundle.main.path(forResource: "1", ofType: "mp4") ?? ""
        
        let admodel = AdFileModel(adUrl: fileGif, adType: .gif, adHerfUrl: "https://github.com/shiliujiejie/RootTabBarController", adId: 1, customSaveKey: nil)
        
        showAdView(admodel)
    }
    
    func showAdView(_ adModel: AdFileModel) {
        let advc = SwiftAdView(config: configModel(), adModel: adModel)
        advc.modalPresentationStyle = .fullScreen
        self.present(advc, animated: false, completion: nil)
        isAdShow = true
        advc.skipBtnClickHandler = {
            
        }
        advc.adClickHandler = { (adModel) in
            let webvc = WebKitController(url: URL(string: adModel.adHerfUrl ?? "")!)
            self.navigationController?.pushViewController(webvc, animated: true)
        }
    }
    
    /// 广告页面属性 - 配置
    func configModel() -> SwiftAdFileConfig {
        let config = SwiftAdFileConfig()
        config.duration = 10
        config.autoDissMiss = false
        config.openInSafari = false
        config.videoGravity = .resizeAspectFill
        return config
    }
    /// 这里模拟网络请求到 广告数据 后的操作
    func loadAdAPI() {
        
        // 模拟网络请求1.5秒
        self.sleep(1.5) {
            /// 请求结果 构造 model (根据了 链接对应的数据 的文件格式。确定 adType : "image"   "gif"  "video")
            // https://github.com/shiliujiejie/adResource/raw/master/1.mp4
            // https://github.com/shiliujiejie/adResource/raw/master/2.mp4
            // https://github.com/shiliujiejie/adResource/raw/master/3.mp4
            // https://github.com/shiliujiejie/adResource/raw/master/folding-cell.gif
            // https://github.com/shiliujiejie/adResource/raw/master/maskp.gif
            // https://github.com/shiliujiejie/adResource/raw/master/timg.jpeg
            // http://cdn-hw.570920.com/video_ad/ao/7c/12ao7c3ee37f66d36b7f413a58d6483054aae59128.m3u8
            
            let admodel = AdFileModel.init(adUrl: "https://github.com/shiliujiejie/adResource/raw/master/2.mp4", adType: .video, adHerfUrl: "https://github.com/shiliujiejie/RootTabBarController", adId: 0 , customSaveKey: nil)
            
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


// MARK: - TSDownloadDelegate
extension RootViewController: TSDownloadDelegate {
    func downloadSpeedUpdate(speed: String) {
        speedlab.text = speed
    }
    
    func tsDownloadSucceeded() {
        print("tsDownloadSucceeded()() ")
        pauseBtn.isHidden = true
        speedlab.text = "已完成下载"
        localVideoBtn.isHidden = false
    }
    func tsDownloadFailed() {
        
    }
    func m3u8ParserSuccess() {
        print("m3u8ParserSuccess() ")
        
        parserBtn.setTitle("准备下载", for: .normal)
    }
    func m3u8ParserFailed() {
        print("m3u8ParserFailed() ")
    }
    func update(progress: Float) {
        print("update(progress:() == \(progress) ")
        let str = String(format: "%.2f%%", progress*100)
        parserBtn.setTitle(str, for: .normal)
    }
  
}
