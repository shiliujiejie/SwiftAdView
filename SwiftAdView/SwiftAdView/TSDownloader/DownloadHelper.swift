
import Foundation
import Alamofire

open class DownLoadHelper: NSObject {
    
    public static let downloadFile = "TSDownloads"
    
    var m3u8Data: String = ""
    var downLoadRequest: DownloadRequest!
    var tsListModel: TSListModel!
    /// 正在下载的 ts 脚标
    var downloadIndex: Int = 0
    /// 已下载时长
    var downLoadedDuration: Float = 0.0
    
    var downloaadSuccessHandler:(() -> Void)?
    var downloaadFailHandler:((_ failMsg: String) -> Void)?
    var progressUpdateHandler:((_ progress: Float) ->Void)?
    
    open class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    open class func checkOrCreatedM3u8Directory(_ identifer: String) {
        let filePath = getDocumentsDirectory().appendingPathComponent(downloadFile).appendingPathComponent(identifer)
        if !FileManager.default.fileExists(atPath: filePath.path) {
            try? FileManager.default.createDirectory(at: filePath, withIntermediateDirectories: true, attributes: nil)
        }
    }
    open class func filesIsExist(_ identifer: String) -> Bool {
        let filePath = getDocumentsDirectory().appendingPathComponent(downloadFile).appendingPathComponent(identifer)
        if FileManager.default.fileExists(atPath: filePath.path) {
            let files = findFiles(path: filePath.path, filterTypes: ["m3u8"])
            if files.count > 0 { // 本地m3u8文件已经存在
                print("文件已存在 -- filePath = \(filePath.path)")
                return true
            }
        }
        return false
    }
    
    /// 删除所有下载
    open class func deleteAllDownloadedContents() {
        let filePath = getDocumentsDirectory().appendingPathComponent(downloadFile).path
        if FileManager.default.fileExists(atPath: filePath) {
            try? FileManager.default.removeItem(atPath: filePath)
        } else {
            print("File has already been deleted.")
        }
    }
    
    /// 根据名称删除已下载视频片段文件夹
    ///
    /// - Parameter name: 文件名
    open class func deleteDownloadedContents(_ identifer: String) {
        let filePath = getDocumentsDirectory().appendingPathComponent(downloadFile).appendingPathComponent(identifer).path
        if FileManager.default.fileExists(atPath: filePath) {
            try? FileManager.default.removeItem(atPath: filePath)
        } else {
            print("Could not find directory with name: \(identifer)")
        }
    }
    
    /// 查找文件夹下所有文件
    class func findFiles(path: String) -> [String]? {
        var files = [String]()
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return nil }
        while let element = enumerator.nextObject() as? String {
            files.append(element)
        }
        return files
    }
    /// 指定类型查找文件夹下文件
    class func findFiles(path: String, filterTypes: [String]) -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: path)
            if filterTypes.count == 0 {
                return files
            } else {
                let filteredfiles = NSArray(array: files).pathsMatchingExtensions(filterTypes)
                return filteredfiles
            }
        } catch {
            return []
        }
    }
    
    /// 根据正则表达式  截取字符串 ：pattern： 正则字符串  str: 被截取字符串
    open class func regexGetSub(pattern: String, str: String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options:[])
        let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex...,in: str))
        if matches.count > 0 {
            print("matches == \(matches)")
            let ss = str[Range(matches[0].range(at: 1), in: str)!]
            return String(ss)
        }
        return ""
    }
}

extension DownLoadHelper {
    
    func downLoadTsFiles(tsLsModel: TSListModel,
                         succeedHandler: @escaping () -> (),
                         failHandler: @escaping (_ failMessage: String) -> (),
                         progressHandler: @escaping (Float) -> ())
    {
        if tsLsModel.tsModelArray.count == 0 {
            print("没有可供下载的 ts")
            return
        }
        tsListModel = tsLsModel
        downloaadSuccessHandler = succeedHandler
        downloaadFailHandler = failHandler
        progressUpdateHandler = progressHandler
        downLoadIndex(0)
    }
    func downLoadIndex(_ index: Int) {
        if index >= tsListModel.tsModelArray.count { return }
        let directoryPath = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(tsListModel.identifier)
        print("directoryPath == \(directoryPath)")
        let tsModel = tsListModel.tsModelArray[index]
        downloadIndex = index
        //下载文件的保存路径
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let fileUrl = directoryPath.appendingPathComponent("\(tsModel.index).ts")
            print("tsFilePath ========== \(fileUrl)")
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        downLoadRequest = Alamofire.download(tsModel.tsUrl, to: destination)
            .downloadProgress { [weak self] progress in
                guard let strongSelf = self else { return }
                let currentDownload = strongSelf.downLoadedDuration + tsModel.duration * Float(progress.fractionCompleted)
                let prog = currentDownload/strongSelf.tsListModel.duration
                DispatchQueue.main.async {
                    strongSelf.progressUpdateHandler?(prog)
                }
        }
        .responseData { [weak self] response in
            guard let strongSelf = self else { return }
            if let _ = response.result.value {
                if index == strongSelf.tsListModel.tsModelArray.count - 1 { // 最后一个
                    print("最后一个下载完成 - 创建本地 .m3u8 文件")
                    strongSelf.createLocalM3U8file()
                    strongSelf.downloaadSuccessHandler?()
                    return
                }
                print("第\(index)个下载完成, 继续下载第 \(index + 1)个")
                strongSelf.downLoadedDuration += tsModel.duration
                self?.downLoadIndex(index+1)
            }
            if let error = response.error {
                var failStr = ""
                if (error as NSError).code  == NSURLErrorCancelled {
                    
                    failStr = "cancel - download"
                } else if (error as NSError).code == NSURLErrorNetworkConnectionLost || (error as NSError).code == NSURLErrorTimedOut
                {
                     failStr = "failed - Network"
                } else {
                      failStr = "failed - download"
                }
                strongSelf.downloaadFailHandler?(failStr)
            }
        }
    }
    
    /// 获取解密字符串
    ///
    /// - Returns: 解密字符串IV
    func getIV() -> String? {
        if !m3u8Data.contains("#EXT-X-KEY:") { return nil }
        // 用正则表达式取出秘钥所在 url
        let m3u8Pes = m3u8Data.components(separatedBy: "\n")
        var keyM3u8 = ""
        for pes in m3u8Pes {
            if pes.contains("IV=") && pes.contains("#EXT-X-KEY:") {
                keyM3u8 = pes.components(separatedBy: "IV=").last ?? ""
            }
        }
        if !keyM3u8.isEmpty {
            return keyM3u8
        }
        return nil
    }
    
    /// 创建本地M3u8文件，播放要用
    func createLocalM3U8file() {
        DownLoadHelper.checkOrCreatedM3u8Directory(tsListModel.identifier)
        
        let filePath = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(tsListModel.identifier).appendingPathComponent("\(tsListModel.identifier).m3u8")
        
        /// 解密的key 所在的路径和ts视频片段在同一文件目录下，所以这里直接用相对路径，如果不在一个文件夹下，需要拼接绝对路径
        let keyPath = "key"
        ///绝对路径
        let keyPathAll = DownLoadHelper.getDocumentsDirectory().appendingPathComponent(DownLoadHelper.downloadFile).appendingPathComponent(tsListModel.identifier).appendingPathComponent("key")
        var header = "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:60\n"
        if m3u8Data.contains("#EXT-X-KEY:") && FileManager.default.fileExists(atPath: keyPathAll.path) {
            var keyStringPath = String(format: "#EXT-X-KEY:METHOD=AES-128,URI=\"%@\"", keyPath)
            if getIV() != nil {
                keyStringPath = String(format: "#EXT-X-KEY:METHOD=AES-128,URI=\"%@\",IV=%@", keyPath,getIV()!)
            }
            header = String(format: "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:60\n%@\n", keyStringPath)
            
        }
        var content = ""
        
        for i in 0 ..< tsListModel.tsModelArray.count {
            let segmentModel = tsListModel.tsModelArray[i]
            let length = "#EXTINF:\(segmentModel.duration),\n"
            let fileName = "\(segmentModel.index).ts\n"
            content += (length + fileName)
        }
        
        header.append(content)
        header.append("#EXT-X-ENDLIST\n")
        print("local m3u8 file str = \(header) ")
        let writeData: Data = header.data(using: .utf8)!
        //try! writeData.write(to: filePath)
        try? writeData.write(to: filePath) 
    }
}


