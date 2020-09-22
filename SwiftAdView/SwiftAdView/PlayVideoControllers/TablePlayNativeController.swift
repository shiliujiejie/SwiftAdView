
import UIKit
import AVKit
import GCDWebServer

class TablePlayNativeController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    ///端口
    private var port: UInt = 8099
    let server = GCDWebServer()
    
    lazy var leftBackButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "navBackWhite"), for: .normal)
        button.backgroundColor = UIColor(white: 0.9, alpha: 0.1)
        button.layer.cornerRadius = 17.5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(backButtonClick), for: .touchUpInside)
        return button
    }()
    /// 这里用UITableView 来做， 也可以使用UICollectionView 一样的效果（纯属 个人习惯）
    lazy var tableView: UITableView = {
        let table = UITableView.init(frame: view.bounds, style: .plain)
        table.backgroundColor = .white
        table.delegate = self
        table.dataSource = self
        table.bounces = false
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.scrollsToTop = false
        table.register(TablePlayCell.classForCoder(), forCellReuseIdentifier: TablePlayCell.cellId)
        return table
    }()
    let tableHeader: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth*9/16))
        view.backgroundColor = UIColor.darkText
        return view
    }()
    let timelabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(white: 0, alpha: 0.1)
        label.textColor = UIColor.white
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 12)
        label.layer.cornerRadius = 2
        label.layer.masksToBounds = true
        return label
    }()
    lazy var playerView: R_PlayerView = {
        let player = R_PlayerView.init(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth*9/16), bothSidesTimelable: true)
        player.videoNameShowOnlyFullScreen = true
        player.delegate = self
        player.customViewDelegate = self
        return player
    }()
    var videos = ["https://melbycdn4.b-cdn.net/201808/20180808/65b9c1290bc3a108141a5c014dcbe1b4/index.m3u8","https://youku.cdn-2-okzy.com/20190115/21070_ad2bd008/index.m3u8","https://iqiyi.cdn27-okzy.com/20200704/5631_0f0e0cd0/index.m3u8","https://youku.cdn7-okzy.com/20200820/20513_6741611c/index.m3u8","https://youku.cdn7-okzy.com/20200904/20640_2ade4805/index.m3u8","https://youku.cdn7-okzy.com/20200820/20512_3241bf7a/index.m3u8","https://sina.com-h-sina.com/20180815/10029_417b3be5/index.m3u8","https://youku.cdn7-okzy.com/20200728/20368_27af4683/index.m3u8","https://youku.cdn7-okzy.com/20200728/20366_c5584e38/1000k/hls/index.m3u8","https://sohu.com-v-sohu.com/20181012/13482_2806d37f/index.m3u8","https://iqiyi.cdn27-okzy.com/20200711/5951_05c7726c/index.m3u8","https://youku.cdn7-okzy.com/20200724/20329_7c82abaa/index.m3u8","https://vip.okokbo.com/20180107/HmCFWhwd/index.m3u8","https://vip.okokbo.com/20180120/lMdBHYFh/index.m3u8","https://56.com-t-56.com/20190627/23470_89309d20/index.m3u8","https://youku.cdn3-okzy.com/20200419/8285_3d2b2d6f/index.m3u8","https://youku.cdn3-okzy.com/20200719/11080_4ea53ad1/index.m3u8","https://youku.cdn7-okzy.com/20200719/20300_cb6a91ac/index.m3u8","https://yj.yongjiu6.com/20180210/09g1MB2Q/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200524/13102_7838a76a/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200607/14223_1f2afd5a/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200531/13637_5df75878/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200517/12507_0da0bffa/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200712/16730_550d0927/1000k/hls/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200705/16190_67e63082/1000k/hls/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200628/15701_c16a85c8/1000k/hls/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200621/15210_3930af1c/index.m3u8","https://sina.com-h-sina.com/20181025/21491_6b227b59/1000k/hls/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200503/11234_5ff64f53/index.m3u8","https://cdn-yong.bejingyongjiu.com/20200426/10541_3220c777/index.m3u8","https://yj.yongjiu6.com/20190320/U6V66mM9/index.m3u8","https://yj.yongjiu6.com/20190320/3ntP7MQB/index.m3u8","https://v3.yongjiujiexi.com/20190517/lT61927Q/index.m3u8","https://tudou.com-l-tudou.com/20180415/8585_af263bbc/1000k/hls/index.m3u8","https://youku.cdn-163.com/20180428/6707_c9d8cb95/index.m3u8","https://yj.yongjiu6.com/20190522/6BAN12VF/index.m3u8","https://txxs.mahua-yongjiu.com/20191128/5576_5014e489/index.m3u8","https://dapian.video-yongjiu.com/20190912/11634_b1fcc590/1000k/hls/index.m3u8","https://ifeng.com-v-ifeng.com/20180716/21984_b1d9151f/index.m3u8","https://youku.cdn7-okzy.com/20200320/17981_b5d8baf6/index.m3u8","https://vip.okokbo.com/20171213/wExbLQbT/index.m3u8","https://youku.cdn3-okzy.com/20200517/9011_95211c33/index.m3u8","https://txxs.mahua-yongjiu.com/20191229/9311_030d73ac/1000k/hls/index.m3u8","https://youku.cdn3-okzy.com/20200510/8835_8aff0fe8/index.m3u8","https://youku.cdn3-okzy.com/20200612/9795_f0b54684/index.m3u8","http://youku163.zuida-bofang.com/20180905/13609_155264ac/index.m3u8","http://yun.kubo-zy-youku.com/20181112/BULbB7PC/index.m3u8","http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4c0c9e59031868222924048327/f0.mp4","https://github.com/shiliujiejie/adResource/raw/master/2.mp4", "https://github.com/shiliujiejie/adResource/raw/master/1.mp4", "https://github.com/shiliujiejie/adResource/raw/master/3.mp4"]
    var currentIndex: Int = 0
    
    var firstIn: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
       
        view.backgroundColor = UIColor.white
        if server.isRunning {
            server.stop()
        }
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor.darkText
        view.addSubview(tableHeader)
        view.addSubview(tableView)
        tableHeader.addSubview(timelabel)
        
//        let first = videos[0]
//        var url = URL(string: first)
//        if !first.hasPrefix("http") {
//            url = URL(fileURLWithPath: first)
//        }
//        playVideo(url!, in: tableHeader)
        
        view.addSubview(leftBackButton)
        layoutPageSubviews()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.playerStatu = .Pause
        if server.isRunning {
            server.stop()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if playerView.superview != nil {
            playerView.playerStatu = .Playing
        }
    }
    
    @objc func backButtonClick() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func playNextVideo(_ index: Int, _ cell: TablePlayCell) {
        if currentIndex != index {
            if let url = URL(string: videos[index]) {
                playVideo(url, in: cell.bgImage)
            }
            currentIndex = index
        }
        /// 设置播放速度
        //playerView.resetRate(rate: 1.5)
    }
    func playVideo(_ url: URL,in view: UIView) {
        let identifer = url.absoluteString.md5()
        if server.isRunning {
            server.stop()
        }
        if DownLoadHelper.filesIsAllExist(identifer) { /// 已缓存
            let pathq = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(identifer).path
            server.addGETHandler(forBasePath: "/", directoryPath: pathq, indexFilename: "\(identifer).m3u8", cacheAge: 3600, allowRangeRequests: true)
            
            server.start(withPort: port, bonjourName: nil)
            
            if server.serverURL != nil {
                let videoLocalUrl = "\(server.serverURL!.absoluteString)\(identifer).m3u8"
                print("videoLocalServerUrl == \(videoLocalUrl)")
                playerView.startPlay(url: URL(string: videoLocalUrl)!, in: view)
            }
        } else {
            /// 可以根据网络是否为wift 确定是否 cache
            playerView.startPlay(url: url, in: view, title: url.absoluteString, uri: nil, cache: false)
        }
    }
}

extension TablePlayNativeController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (screenWidth - 20) * 9/16 + 40
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TablePlayCell.cellId, for: indexPath) as! TablePlayCell
        cell.nameLabel.text = videos[indexPath.row]
        if firstIn && indexPath.row == 0 {
            if let url = URL(string: videos[indexPath.row]) {
                playVideo(url, in: cell.bgImage)
                firstIn = false
            }
        }
//        cell.playActionHandle = { [weak self] in
//            guard let strongSelf = self else { return }
//            strongSelf.playNextVideo(indexPath.row, cell)
//        }
        return cell
    }
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //重用问题 ，这里去处理吧
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
//MARK: - UIScrollViewDelegate
extension TablePlayNativeController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        playerView.pause(false)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollItemsPlay()
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollItemsPlay()
        }
    }
    @objc func scrollItemsPlay() {
        
        guard let indexPaths = tableView.indexPathsForVisibleRows?.sorted() else { return }
        if indexPaths.count > 0 && indexPaths.count <= 2 {
            var playIndex: IndexPath?
            let indexLast = indexPaths.last
            if let indexlast = indexPaths.last, indexLast?.item == videos.count - 1 { // 滑到最后
                playIndex = indexlast
            } else {
                playIndex = indexPaths[0]
            }
            
            if let cell = tableView.cellForRow(at: playIndex!) as? TablePlayCell {
                // print("indexPath == \(indexPath)")
                if let url = URL(string: videos[indexPaths[0].item]) {
                    //playerView.startPlay(url: url, in: cell.coverImg)
                    playVideo(url, in: cell.bgImage)
//                    player.player?.volume = 0
//                    player.playerIsUserInteractionEnabled(false)
                }
            }
        } else if indexPaths.count > 2 {
            if let cell = tableView.cellForRow(at: indexPaths[1]) as? TablePlayCell {
                // print("indexPath == \(indexPath)")
                if let url = URL(string: videos[indexPaths[1].item]) {
                    playVideo(url, in: cell.bgImage)
                }
            }
        }
        print("indexPaths == \(indexPaths), indexPathsCount = \(indexPaths.count)")
    }
}

extension TablePlayNativeController: R_PlayerDelegate {
    func startPlay() {
        print("startPlay")
    }
    func retryToPlayVideo(url: URL?) {
        print("retryToPlayVideo = \(url?.absoluteString ?? "")")
    }
    func playVideoFailed(url: URL?, player: R_PlayerView) {
        print("playVideoFailed")
    }
    func playerProgress(progress: Float, currentPlayTime: Float) {
        print("playerProgress = \(progress) currentPlayTime = \(currentPlayTime)")
    }
    func currentVideoPlayToEnd(url: URL?, isPlayingloaclFile: Bool) {
        print("currentVideoPlayToEnd = \(isPlayingloaclFile)")
        //playerView.replay()
    }
}

/// 自定义 附加操作视图(全屏状态下)
extension TablePlayNativeController: R_CustomMenuDelegate {
    
    func showCustomMuneView() -> UIView? {
        /// 谁持有，谁释放 （若 CustomActionsView 为当前控制器的全局变量，需要当前控制器释放）
        let view1 = CustomActionsView(frame: self.view.bounds)
        
        view1.itemClick = { [weak self] index in
            print("itemClick ===== \(index)")
            if index == 0 {
                self?.playerView.resetRate(rate: 1.0)
            } else if index == 1 {
                self?.playerView.resetRate(rate: 1.2)
            } else if index == 2 {
                self?.playerView.resetRate(rate: 1.5)
            }
        }
        return view1
    }
}

// MARK: - Layout
private extension TablePlayNativeController {
    
    func layoutPageSubviews() {
        layoutTableHeader()
        layoutTableView()
        layoutLeftBackButton()
        layouTimeLabel()
    }
    func layoutTableHeader() {
        tableHeader.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(statusBarHeight)
            make.height.equalTo(screenWidth*9/16)
        }
    }
    func layoutTableView() {
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(tableHeader.snp.bottom)
        }
    }
    func layoutLeftBackButton() {
        leftBackButton.snp.makeConstraints { (make) in
            make.leading.equalTo(10)
            make.top.equalTo(screenHeight >= 812 ? 48 : 24)
            make.width.height.equalTo(35)
        }
    }
    
    func layouTimeLabel() {
        timelabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(-10)
            make.bottom.equalTo(-7.5)
            make.height.equalTo(16)
        }
    }
}
