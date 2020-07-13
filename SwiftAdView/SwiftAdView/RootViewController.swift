
import UIKit

class RootViewController: UIViewController {
    
    static let titles = ["show screen ad again","show short video play","list video show","TablePlayNative","add categary title","Bluetooth"]
    
    private lazy var table: UITableView = {
        let ta = UITableView(frame: CGRect(x: 0, y: 220, width: view.bounds.width  , height: view.bounds.height - 220), style: .plain)
        ta.showsVerticalScrollIndicator = false
        ta.delegate = self
        ta.dataSource = self
        ta.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "nothing")
        return ta
    }()
    private lazy var parserBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("下载", for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(parseM3u8(_:)), for: .touchUpInside)
        btn.frame = CGRect(x: 30, y: 100, width: 100, height: 40)
        return btn
    }()
    private lazy var pauseBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("pause", for: .normal)
        btn.setTitle("resume", for: .selected)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.addTarget(self, action: #selector(showVideoVC(_:)), for: .touchUpInside)
        btn.frame = CGRect(x: 150, y: 100, width: 70, height: 40)
        btn.isHidden = true
        return btn
    }()
    private let speedlab: UILabel = {
        let lab = UILabel()
        lab.frame = CGRect(x: 250, y: 100, width: 100, height: 40)
        return lab
    }()
    
    private lazy var localVideoBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("playLocal", for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(showVideoVC(_:)), for: .touchUpInside)
        btn.frame = CGRect(x: 30, y: 150, width: 100, height: 40)
        btn.isHidden = true
        return btn
    }()
    
    lazy var tsManager: TSManager = {
        let tsm = TSManager()
        tsm.delegate = self
        return tsm
    }()
    
    //1层加密 ：http://cdn.wayada.com/video_user/ot/n4/12otn4aa4b3ac33d1a685cb04d1b20312396a61069.m3u8
    //非加密 2层 "http://yun.kubo-zy-youku.com/20181112/BULbB7PC/index.m3u8"
    //"https://video.kkyun-iqiyi.com/20180301/WNvThg3j/index.m3u8"
    
    let videoUrl = "https://video.kkyun-iqiyi.com/20180301/WNvThg3j/index.m3u8" //"https://video.kkyun-iqiyi.com/20180301/WNvThg3j/index.m3u8"
      //"https://vs1.baduziyuan.com/20180106/5hykgzke/800kb/hls/index.m3u8"
     //"https://www.nmgxwhz.com:65/20200328/mmTagJcX/index.m3u8"
    //"http://yun.kubo-zy-youku.com/20181112/BULbB7PC/index.m3u8"
    var isAdShow: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        self.title = "首页"
        view.addSubview(parserBtn)
        view.addSubview(pauseBtn)
        view.addSubview(speedlab)
        view.addSubview(localVideoBtn)
        view.addSubview(table)
        
        /// 闪屏广告
        showAd()
        
        if tsManager.downloadSucceeded(videoUrl.md5()) { /// 先判断是否已经下载成功
            parserBtn.setTitle("已下载", for: .normal)
            parserBtn.tag = -1  // 可以用枚举替代
            speedlab.text = "已完成下载"
            localVideoBtn.isHidden = false
        } else {
            if tsManager.isInterruptTask(videoUrl.md5()) { /// 是否下载中断
                parserBtn.setTitle("继续下载", for: .normal)
                parserBtn.tag = 99
            } else {
                parserBtn.setTitle("下载", for: .normal)
                parserBtn.tag = 0
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func showAd() {
        loadADView()
    }
    
    @objc func showVideoVC(_ sender: UIButton) {
        if sender == localVideoBtn {
            let identifer = videoUrl.md5()
            if tsManager.downloadSucceeded(identifer) {
                let localPlayVC = DownLoadedVideoPlayerVC()
                localPlayVC.identifer = identifer
                navigationController?.pushViewController(localPlayVC, animated: true)
            }
        } else if sender == pauseBtn {
            if sender.isSelected {
                tsManager.resume()
                sender.isSelected = false
            } else {
                tsManager.pause()
                sender.isSelected = true
            }
        }
    }
    
    @objc func parseM3u8(_ sender: UIButton) {
        
        if sender.tag == 99 {
            sender.setTitle("解析中...", for: .normal)
            tsManager.directoryName = videoUrl.md5()
            tsManager.m3u8URL = videoUrl
            tsManager.downloadFromLastInterruptedIndex()
            pauseBtn.isHidden = false
        } else if sender.tag == -1 {
            print("当前视频已经下载了")
        } else if sender.tag == 0 {
            sender.setTitle("解析中...", for: .normal)
            tsManager.directoryName = videoUrl.md5()
            tsManager.m3u8URL = videoUrl
            tsManager.download()
            pauseBtn.isHidden = false
        }
    }
    
}

extension RootViewController: UITableViewDelegate , UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RootViewController.titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nothing", for: indexPath)
        cell.textLabel?.text = RootViewController.titles[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            showAd()
            
            break
        case 1:
            let c = ShortPlayController()
            navigationController?.pushViewController(c, animated: true)
            break
        case 2:
            let cc = VideoTableController()
            navigationController?.pushViewController(cc, animated: true)
            break
            case 3:
            let c = TablePlayNativeController()
            navigationController?.pushViewController(c, animated: true)
            break
        case 4:
            let categoryVC = CategrayController()
            self.navigationController?.pushViewController(categoryVC, animated: true)
            break
        case 5:
            let c = BluetoothController()
            navigationController?.pushViewController(c, animated: true)
            break
            
        default:
            break
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
