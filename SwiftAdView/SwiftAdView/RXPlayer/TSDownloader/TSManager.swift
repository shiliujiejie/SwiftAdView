
import UIKit

protocol TSDownloadDelegate: class {
    func tsDownloadSucceeded()
    func tsDownloadFailed()
    func update(progress: Float)
    func downloadSpeedUpdate(speed: String)
    func m3u8ParserSuccess()
    func m3u8ParserFailed()
}

class TSManager: NSObject {
    
    static let kIdentifier = "identifier"
    static let kLocalTimes = "downloadTsTimes"
    static let kInterruptIndex = "interruptIndex"
    
    public var directoryName: String = "" {
        didSet {
            m3u8Parser.identifier = directoryName
        }
    }
    public var m3u8URL = ""
    public weak var delegate: TSDownloadDelegate?
    
    private let m3u8Parser = M3u8Parser()
    private let downLoader = DownLoadHelper()
    
    /// 解析url
    open func parse(_ uriKey: String? = nil) {
        m3u8Parser.parseM3u8(url: m3u8URL, key: uriKey, succeedHandler: { [weak self] (tsList) in
            NLog("tsList == \(tsList.tsModelArray)")
            self?.delegate?.m3u8ParserSuccess()
        }) { [weak self] (errorMsg) in
            NLog(" 解析失败描述 = \(errorMsg)")
            self?.delegate?.m3u8ParserFailed()
        }
    }
    /// 下载
    open func download(_ uriKey: String? = nil) {
        m3u8Parser.parseM3u8(url: m3u8URL, key: uriKey, succeedHandler: { [weak self] (tsList) in
            //NLog("tsModelLs == \(tsList.tsModelArray)")
            self?.delegate?.m3u8ParserSuccess()
            self?.downLoadTsModels(tsList)
        }) { [weak self] (errorMsg) in
            NLog(" 解析失败描述 = \(errorMsg)")
            self?.delegate?.m3u8ParserFailed()
        }
    }
    /// app意外杀进程后，再次启动，从上次中断的位置断点续传
    open func downloadFromLastInterruptedIndex() {
        guard let paramInterrupt = getLastInterruptIndex() else {
            return
        }
        m3u8Parser.parseM3u8(url: m3u8URL, succeedHandler: { [weak self] (tsList) in
            guard let strongSelf = self else { return }
            self?.delegate?.m3u8ParserSuccess()
            self?.downLoader.m3u8Data = strongSelf.m3u8Parser.m3u8Data
            self?.downLoader.downLoadedDuration = paramInterrupt[TSManager.kLocalTimes] as! Float
            self?.downLoadFromLastInterrupt(index: paramInterrupt[TSManager.kInterruptIndex] as! Int , tsListModel: tsList)
        }) { [weak self] (errorMsg) in
            NLog(" 解析失败描述 = \(errorMsg)")
            self?.delegate?.m3u8ParserFailed()
        }
    }
    /// 暂停
    open func pause() {
        downLoader.pauseDownload()
    }
    /// app内 pause(暂停) 后，click resume（点击 继续下载）
    open func resume() {
        downLoader.resume()
    }
    /// 删除所有下载好的本地文件夹
    open func removeAllCacheFiles() {
        DownLoadHelper.deleteAllDownloadedContents()
    }
    /// 置顶文件夹名删除本地文件夹
    open func deleteFile(_ identifer: String) {
        DownLoadHelper.deleteDownloadedContents(identifer)
    }
    /// 是否被中断的下载
    open func isInterruptTask(_ identifer: String) -> Bool {
        return DownLoadHelper.checkIsInterruptDownload(identifer)
    }
    /// 是否已成功下载
    open func downloadSucceeded(_ identifer: String) -> Bool  {
        return DownLoadHelper.filesIsAllExist(identifer)
    }
    /// 中断下载
    open func downlodInterrupt() {
        NLog("中断下载")
        downLoader.pauseDownload()
        saveInterruptIndex()
    }
    
}

private extension TSManager {
    
    /// 获取上次中断下载的ts的 index
    func getLastInterruptIndex() -> [String: Any]? {
//        if let paramInterrupt = UserDefaults.standard.value(forKey: directoryName) as? [String : Any] {
//            print("paramInterrupt --- get = \(paramInterrupt))")
//            return paramInterrupt
//        }
        let plistFilePath = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(DownLoadHelper.interruptPlist)
        if FileManager.default.fileExists(atPath: plistFilePath.path) {
            if let paramInterrupt = NSMutableArray(contentsOf: plistFilePath) {
                let interruptCurrent = paramInterrupt.filter { (dic) -> Bool in
                    return ((dic as! NSDictionary)[TSManager.kIdentifier] as! String) == directoryName
                }
                if interruptCurrent.count > 0 {
                    return (interruptCurrent[0] as! [String : Any])
                }
            }
        }
        return nil
    }
    /// 保存中断下载的ts index
    func saveInterruptIndex() {
        if downLoader.downloadIndex == 0 || downLoader.downLoadedDuration == 0 { return }
        let paramKey: NSDictionary = [TSManager.kIdentifier : directoryName,TSManager.kLocalTimes: downLoader.downLoadedDuration, TSManager.kInterruptIndex: downLoader.downloadIndex]
        let sourceArray = NSMutableArray()
        sourceArray.add(paramKey)
        let plistFilePath = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(DownLoadHelper.interruptPlist)
        if !FileManager.default.fileExists(atPath: plistFilePath.path) { /// 文件不存在
            sourceArray.write(to: plistFilePath, atomically: true)
        } else {
            if let source = NSMutableArray(contentsOf: plistFilePath) {
                let interruptCurrent = source.filter { (dic) -> Bool in
                    return ((dic as! NSDictionary)[TSManager.kIdentifier] as! String) == directoryName
                }
                if interruptCurrent.count == 0 {
                    source.add(paramKey)
                } else {
                    if let indexLast = (interruptCurrent[0] as! NSDictionary)[TSManager.kInterruptIndex] as? Int {
                        if indexLast < downLoader.downloadIndex {
                            source.remove(interruptCurrent[0])
                            source.add(paramKey)
                        }
                    } else {
                        source.remove(interruptCurrent[0])
                        source.add(paramKey)
                    }
                }
                source.write(to: plistFilePath, atomically: true)
            }
        }
       // UserDefaults.standard.set(paramKey, forKey: directoryName)
        NLog("paramInterrupt --- save = \(paramKey)")
    }
    /// 删除中断下载的ts index
    func deleteInterruptIndex() {
        let plistFilePath = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(DownLoadHelper.interruptPlist)
        if FileManager.default.fileExists(atPath: plistFilePath.path) {
            if let source = NSMutableArray(contentsOf: plistFilePath) {
                let interruptCurrent = source.filter { (dic) -> Bool in
                    return ((dic as! NSDictionary)[TSManager.kIdentifier] as! String) == directoryName
                }
                if interruptCurrent.count > 0 {
                    source.remove(interruptCurrent[0])
                    source.write(to: plistFilePath, atomically: true)
                }
            }
        }
        //UserDefaults.standard.removeObject(forKey: directoryName)
    }
    func downLoadTsModels(_ tsListModel: TSListModel) {
        downLoader.m3u8Data = m3u8Parser.m3u8Data
        downLoader.downLoadTsFiles(index: 0,tsLsModel: tsListModel, succeedHandler: { [weak self] in
            NLog(" all ts file download succeed")
            self?.deleteInterruptIndex()
            DispatchQueue.main.async {
                self?.delegate?.tsDownloadSucceeded()
            }
            }, failHandler: { [weak self] (error) in
                NLog("error msg == \(error)")
                DispatchQueue.main.async {
                    self?.delegate?.tsDownloadFailed()
                }
            }, progressHandler: { [weak self] (progress) in
                DispatchQueue.main.async {
                   self?.delegate?.update(progress: progress)
                }
        }) { [weak self] (speed) in
            DispatchQueue.main.async {
                self?.delegate?.downloadSpeedUpdate(speed: speed)
            }
        }
        addNotifacation()
    }
    func downLoadFromLastInterrupt(index: Int, tsListModel: TSListModel) {
        if index >= tsListModel.tsModelArray.count { return }
        downLoader.m3u8Data = m3u8Parser.m3u8Data
        downLoader.downLoadTsFiles(index: index,tsLsModel: tsListModel, succeedHandler: { [weak self] in
            NLog(" all ts file download succeed")
            self?.deleteInterruptIndex()
            DispatchQueue.main.async {
               self?.delegate?.tsDownloadSucceeded()
            }
            }, failHandler: { [weak self] (error) in
                NLog("error msg == \(error)")
                DispatchQueue.main.async {
                    self?.delegate?.tsDownloadFailed()
                }
            }, progressHandler: { [weak self] (progress) in
                DispatchQueue.main.async {
                    self?.delegate?.update(progress: progress)
                }
        }) { [weak self] (speed) in
            DispatchQueue.main.async {
                self?.delegate?.downloadSpeedUpdate(speed: speed)
            }
        }
        addNotifacation()
    }
    func addNotifacation() {
        // 注册APP被挂起 + 进入前台通知
        NotificationCenter.default.addObserver(self, selector: #selector(applicationResignActivity(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActivity(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}

extension TSManager {
    
    // MARK: - APP将要被挂起
    @objc func applicationResignActivity(_ sender: NSNotification) {
        NLog("applicationResignActivity")
        pause()
        saveInterruptIndex()
    }
    
    // MARK: - APP进入前台，恢复播放状态
    @objc func applicationBecomeActivity(_ sender: NSNotification) {
        NLog("applicationBecomeActivity")
        resume()
        deleteInterruptIndex()
    }
}
