
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
    
    open func parse() {
        m3u8Parser.parseM3u8(url: m3u8URL, succeedHandler: { [weak self] (tsList) in
            print("tsList == \(tsList.tsModelArray)")
            self?.delegate?.m3u8ParserSuccess()
        }) { [weak self] (errorMsg) in
            print(" 解析失败描述 = \(errorMsg)")
             self?.delegate?.m3u8ParserFailed()
        }
    }
    open func download() {
        m3u8Parser.parseM3u8(url: m3u8URL, succeedHandler: { [weak self] (tsList) in
            print("tsModelLs == \(tsList.tsModelArray)")
            self?.delegate?.m3u8ParserSuccess()
            self?.downLoadTsModels(tsList)
        }) { [weak self] (errorMsg) in
            print(" 解析失败描述 = \(errorMsg)")
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
            print(" 解析失败描述 = \(errorMsg)")
            self?.delegate?.m3u8ParserFailed()
        }
    }
    open func pause() {
        downLoader.pauseDownload()
    }
    /// app内 pause(暂停) 后，click resume（点击 继续下载）
    open func resume() {
        downLoader.resume()
    }
    
}

private extension TSManager {
    
    /// 获取上次中断下载的ts的 index
    func getLastInterruptIndex() -> [String: Any]? {
        if let paramInterrupt = UserDefaults.standard.value(forKey: directoryName) as? [String : Any] {
            print("paramInterrupt --- get = \(paramInterrupt))")
            return paramInterrupt
        }
        return nil
    }
    /// 保存中断下载的ts index
    func saveInterruptIndex() {
        let params: [String : Any] = [TSManager.kLocalTimes: downLoader.downLoadedDuration, TSManager.kInterruptIndex: downLoader.downloadIndex]
        UserDefaults.standard.set(params, forKey: directoryName)
        print("paramInterrupt --- save = \(params)")
    }
    /// 删除中断下载的ts index
    func deleteInterruptIndex() {
        UserDefaults.standard.removeObject(forKey: directoryName)
    }
    func downLoadTsModels(_ tsListModel: TSListModel) {
        downLoader.m3u8Data = m3u8Parser.m3u8Data
        downLoader.downLoadTsFiles(index: 0,tsLsModel: tsListModel, succeedHandler: { [weak self] in
            print(" all ts file download succeed")
            DispatchQueue.main.async {
                self?.delegate?.tsDownloadSucceeded()
            }
            }, failHandler: { [weak self] (error) in
                print("error msg == \(error)")
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
            print(" all ts file download succeed")
            DispatchQueue.main.async {
               self?.delegate?.tsDownloadSucceeded()
            }
            }, failHandler: { [weak self] (error) in
                print("error msg == \(error)")
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
        print("applicationResignActivity")
        pause()
        saveInterruptIndex()
    }
    
    // MARK: - APP进入前台，恢复播放状态
    @objc func applicationBecomeActivity(_ sender: NSNotification) {
        print("applicationBecomeActivity")
        resume()
        deleteInterruptIndex()
    }
}
