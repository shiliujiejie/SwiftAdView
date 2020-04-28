
import UIKit


protocol TSDownloadDelegate: class {
    func tsDownloadSucceeded()
    func tsDownloadFailed()
    func update(progress: Float)
    func m3u8ParserSuccess()
    func m3u8ParserFailed()
}

class TSManager: NSObject {
    public var directoryName: String = "" {
        didSet {
            m3u8Parser.identifier = directoryName
        }
    }
    public var m3u8URL = ""
    private let m3u8Parser = M3u8Parser()
    private let downLoader = DownLoadHelper()
    public weak var delegate: TSDownloadDelegate?
    
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
    private func downLoadTsModels(_ tsListModel: TSListModel) {
        downLoader.m3u8Data = m3u8Parser.m3u8Data
        downLoader.downLoadTsFiles(tsLsModel: tsListModel, succeedHandler: { [weak self] in
            print(" all ts file download succeed")
            self?.delegate?.tsDownloadSucceeded()
        }, failHandler: {  [weak self] (error) in
            print("error msg == \(error)")
            self?.delegate?.tsDownloadFailed()
        }) {  [weak self] (progress) in
            self?.delegate?.update(progress: progress)
        }
    }

}

