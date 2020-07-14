
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
        return player
    }()
     var videos = ["https://vip.okokbo.com/20171213/wExbLQbT/index.m3u8","https://youku.cdn3-okzy.com/20200517/9011_95211c33/index.m3u8","https://txxs.mahua-yongjiu.com/20191229/9311_030d73ac/1000k/hls/index.m3u8","https://youku.cdn3-okzy.com/20200510/8835_8aff0fe8/index.m3u8","https://youku.cdn3-okzy.com/20200612/9795_f0b54684/index.m3u8","http://youku163.zuida-bofang.com/20180905/13609_155264ac/index.m3u8","http://yun.kubo-zy-youku.com/20181112/BULbB7PC/index.m3u8","http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4c0c9e59031868222924048327/f0.mp4","https://github.com/shiliujiejie/adResource/raw/master/2.mp4", "https://github.com/shiliujiejie/adResource/raw/master/1.mp4", "https://github.com/shiliujiejie/adResource/raw/master/3.mp4"]
    var currentIndex: Int = 0
    
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
        
        let first = videos[0]
        var url = URL(string: first)
        if !first.hasPrefix("http") {
            url = URL(fileURLWithPath: first)
        }
        playVideo(url!, in: tableHeader)
       
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
    
    func playNextVideo(_ index: Int) {
        if currentIndex != index {
            if let url = URL(string: videos[index]) {
                playVideo(url, in: tableHeader)
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
        cell.playActionHandle = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.playNextVideo(indexPath.row)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
         //重用问题 ，这里去处理吧
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension TablePlayNativeController: R_PlayerDelegate {
    func retryToPlayVideo(_ player: R_PlayerView, _ videoModel: RXVideoModel?, _ fatherView: UIView?) {
        
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
