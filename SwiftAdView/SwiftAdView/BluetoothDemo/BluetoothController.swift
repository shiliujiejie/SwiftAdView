
import UIKit
import MultipeerConnectivity

class BluetoothController: UIViewController {
    
    lazy var me: MCPeerID = {
        let peer: MCPeerID
        peer = MCPeerID(displayName:"蓝牙设备：\(UIDevice.current.name)")
        return peer
    }()
    lazy var session: MCSession = {
        let s = MCSession(peer: me, securityIdentity: nil, encryptionPreference: .none)
        s.delegate = self
        return s
    }()
    lazy var advertiser: MCNearbyServiceAdvertiser = {
        let a = MCNearbyServiceAdvertiser(peer: me, discoveryInfo: ["demo": "data"], serviceType: "MultipeerDemo")
        a.delegate = self
        return a
    }()
   
    var browserController: MCBrowserViewController?
    private let bgImage : UIImageView = {
        let image = UIImageView(frame: CGRect(x: 0, y: 360, width: screenWidth, height: screenHeight - 380))
        image.isUserInteractionEnabled = true
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        return image
    }()
    private lazy var searchBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("Searching", for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(search), for: .touchUpInside)
        btn.frame = CGRect(x: 30, y: 90, width: screenWidth - 60, height: 40)
        return btn
    }()
    private lazy var disconectBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("Connect", for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(disConnect(_:)), for: .touchUpInside)
        btn.frame = CGRect(x: 30, y: 150, width: screenWidth - 60, height: 40)
        return btn
    }()
    static let titles = ["Send Text Data","Send File Data","Send File Resource"]
    
    private lazy var table: UITableView = {
        let ta = UITableView(frame: CGRect(x: 0, y: 200, width: view.bounds.width  , height: 150), style: .plain)
        ta.showsVerticalScrollIndicator = false
        ta.delegate = self
        ta.dataSource = self
        ta.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "nothing")
        return ta
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.addSubview(bgImage)
        view.addSubview(searchBtn)
        view.addSubview(disconectBtn)
        view.addSubview(table)
        startAdvertising()
    }
    
    @objc func search() {
        startSearching()
    }
    
    @objc func disConnect(_ sender: UIButton) {
        if sender.tag == 0 {
           startSearching()
        } else if sender.tag == 99 {
            session.disconnect()
        }
    }
    
    func startAdvertising() {
        // MD
        advertiser.startAdvertisingPeer()
    }
    
    func startSearching(){
        /// browserController 不好看？ 那就自定义一个， -》〉》 open class MCBrowserViewController : UIViewController, MCNearbyServiceBrowserDelegate
        browserController = MCBrowserViewController(serviceType: "MultipeerDemo", session: session)
        browserController!.delegate = self
        present(browserController!, animated: true, completion: nil)
    }
    /// 发文字 data
    func sendText() {
      
        let text = "这是一条测试数据，测试发送"
        guard let data = text.data(using: .utf8) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .unreliable)
    }
    
    /// 发图片 data
    func sendPictureData() {
        guard let picPath = Bundle.main.path(forResource: "guide02", ofType: "png") else {
            print("Picture is not found")
            return
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: picPath)) {
            try? session.send(data, toPeers: session.connectedPeers, with: .unreliable)
        }
    }
    /// 从文件路径发送文件
    func sendFileWithResource() {
        guard let peer = session.connectedPeers.last else {
            NSLog("No connected peers to send to")
            return
        }
        guard let picPath = Bundle.main.path(forResource: "guide02", ofType: "png") else {
            print("Picture is not found")
            return
        }
        let pathUrl = URL(fileURLWithPath: picPath)
        session.sendResource(at: pathUrl, withName: "guide02", toPeer: peer, withCompletionHandler: { (error) in
            print("error === \(error.debugDescription)")
        })
    }
    func showRecieveText(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension BluetoothController: UITableViewDelegate , UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BluetoothController.titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nothing", for: indexPath)
        cell.textLabel?.text = BluetoothController.titles[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            sendText()
            break
        case 1:
            sendPictureData()
            break
        case 2:
            sendFileWithResource()
            break
        default:
            break
        }
    }
}

// MARK: - MCSessionDelegate
extension BluetoothController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Now connected to \(peerID.displayName)")
            DispatchQueue.main.async {
                self.searchBtn.setTitle("Connect-\(peerID.displayName)", for: .normal)
                self.disconectBtn.setTitle("DisConnect", for: .normal)
                self.disconectBtn.tag = 99
            }
        case .connecting:
            print("Connecting to \(peerID.displayName)")
            
        case .notConnected:
            print("NOT connected to \(peerID.displayName)")
            DispatchQueue.main.async {
                self.disconectBtn.setTitle("Connect", for: .normal)
                self.searchBtn.setTitle("Search", for: .normal)
                self.disconectBtn.tag = 0
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Started Receive data: \(data)")
        if let text = String(data: data, encoding: .utf8) {
            print("Receive data text = \(text)")
            DispatchQueue.main.async {
                self.showRecieveText(text)
            }
        }
        if let image = UIImage(data: data) {
            print("Receive data image = \(image)")
            DispatchQueue.main.async {
                self.bgImage.image = image
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Started stream download: \(streamName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Started resource download: \(resourceName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Finished resource download: \(resourceName)")
        guard let url = localURL else { return }
        print("url ==\(url.absoluteString)")
        guard let data = try? Data(contentsOf: url) else { return }
        if let image = UIImage(data: data) {
            print("Receive Source image = \(image)")
            DispatchQueue.main.async {
                self.bgImage.image = image
            }
        }
    }
    
}

extension BluetoothController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        print("已选择连接")
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        print("取消选择连接")
        browserViewController.dismiss(animated: true, completion: nil)
    }
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        print("发现附近的设备== \(peerID.displayName)")
        return true
    }
}

extension BluetoothController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // This is insecure! We should verify that the peer is valid and etc etc
        print("advertiser ===========")
        invitationHandler(true, session)    //确认连接，把session赋给它
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
          print("Advertising failed with error \(String(describing: error))")
    }
}


