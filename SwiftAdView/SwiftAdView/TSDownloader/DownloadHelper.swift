
import Foundation
import Alamofire

public class DownLoadHelper: NSObject {
    
    public static let downloadFile = "TSDownloads"
    
    var m3u8Data: String = ""
    
    var downLoadRequest: DownloadRequest!
    //用于停止下载时，保存已下载的部分
    var resumeData: Data?
    
    var tsListModel: TSListModel!
    /// 正在下载的 ts 脚标
    var downloadIndex: Int = 0
    /// 已下载时长
    var downLoadedDuration: Float = 0.0
    /// 某个ts下载失败后重试1次， 为1时，不再下载，0时重试一次
    private var retryTimes: Int = 0
    /// 当前正在下载的ts文件的总大小（byte）
    private var tsDataByte: Int64 = 0
    
    var downloadSuccessHandler:(() -> Void)?
    var downloadFailHandler:((_ failMsg: String) -> Void)?
    var progressUpdateHandler:((_ progress: Float) ->Void)?
    var networkSpeedUpdateHandler:((_ speed: String) ->Void)?
    
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
    /// 返回 是否是中断下载
    open class func checkIsInterruptDownload(_ identifer: String) -> Bool {
        let filePath = getDocumentsDirectory().appendingPathComponent(downloadFile).appendingPathComponent(identifer)
        if FileManager.default.fileExists(atPath: filePath.path) {
            let fileM3u8 = findFiles(path: filePath.path, filterTypes: ["m3u8"])
            let fileTS = findFiles(path: filePath.path, filterTypes: ["ts"])
            if fileM3u8.count == 0 && fileTS.count > 0 {
                return true
            }
        }
        return false
    }
    /// 是否已经是下载完成的文件夹
    open class func filesIsAllExist(_ identifer: String) -> Bool {
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
    
    /// 指定删除某个m3u8本地缓存的文件件
    ///
    /// - Parameter identifer: 文件夹名
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
    class func regexGetSub(pattern: String, str: String) -> String {
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
    
    func pauseDownload() {
        if downLoadRequest != nil {
            downLoadRequest.cancel()
        }
    }
    func resume() {
        guard let resuData = resumeData else {
            downLoadIndex(downloadIndex)
            return
        }
        let index = downloadIndex
        let directoryPath = DownLoadHelper.getDocumentsDirectory()
            .appendingPathComponent(DownLoadHelper.downloadFile)
            .appendingPathComponent(tsListModel.identifier)
        print("directoryPath == \(directoryPath)")
        let tsModel = tsListModel.tsModelArray[index]
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let fileUrl = directoryPath.appendingPathComponent("\(tsModel.index).ts")
            print("tsFilePath ========== \(fileUrl)")
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        downLoadRequest = Alamofire.download(resumingWith: resuData, to: destination)
                .downloadProgress(closure: { [weak self] (progress) in
                    guard let strongSelf = self else { return }
                    strongSelf.tsDataByte = progress.totalUnitCount
                    let currentDownload = strongSelf.downLoadedDuration + tsModel.duration * Float(progress.fractionCompleted)
                    let prog = currentDownload/strongSelf.tsListModel.duration
                    strongSelf.progressUpdateHandler?(prog)
                })
            .responseData { [weak self] response in
                guard let strongSelf = self else { return }
                if let _ = response.result.value {
                    if index == strongSelf.tsListModel.tsModelArray.count - 1 { // 最后一个
                        print("The last ts downloaded - create local .m3u8 文件")
                        strongSelf.createLocalM3U8file()
                        strongSelf.downloadSuccessHandler?()
                        return
                    }
                    print("第\(index)个下载完成, 继续下载第 \(index + 1)个")
                    strongSelf.downLoadedDuration += tsModel.duration
                    self?.downLoadIndex(index+1)
                }
                if let error = response.error {
                    if (error as NSError).code  == NSURLErrorCancelled {
                        print("continue - cancel - download")
                        strongSelf.resumeData = response.resumeData
                    } else
                    {
                         print("continue - failed - download")
                        if strongSelf.retryTimes < 1 {  //重试下载
                            strongSelf.retryTimes += 1
                            strongSelf.downLoadIndex(index)
                        } else {
                            strongSelf.downloadFailHandler?("continue - failed - download")
                        }
                    }
                }
            }
    }
    
}

extension DownLoadHelper {
    
    func downLoadTsFiles(index: Int,
                         tsLsModel: TSListModel,
                         succeedHandler: @escaping () -> (),
                         failHandler: @escaping (_ failMessage: String) -> (),
                         progressHandler: @escaping (Float) -> (),
                         speedUpdateHandler: @escaping (String) -> ())
    {
        if tsLsModel.tsModelArray.count == 0 {
            print("没有可供下载的 ts")
            return
        }
        if index >= tsLsModel.tsModelArray.count { return }
        tsListModel = tsLsModel
        downloadSuccessHandler = succeedHandler
        downloadFailHandler = failHandler
        progressUpdateHandler = progressHandler
        networkSpeedUpdateHandler = speedUpdateHandler
        downLoadIndex(index)
    }
    
    func downLoadIndex(_ index: Int) {
        if index >= tsListModel.tsModelArray.count { return }
        let directoryPath = DownLoadHelper.getDocumentsDirectory()
            .appendingPathComponent(DownLoadHelper.downloadFile)
            .appendingPathComponent(tsListModel.identifier)
        print("directoryPath == \(directoryPath)")
        let tsModel = tsListModel.tsModelArray[index]
        downloadIndex = index
        //下载文件的保存路径
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let fileUrl = directoryPath.appendingPathComponent("\(tsModel.index).ts")
            print("tsFilePath ========== \(fileUrl)")
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        let date = Date()
        downLoadRequest = Alamofire.download(tsModel.tsUrl, to: destination)
            .downloadProgress { [weak self] progress in
                guard let strongSelf = self else { return }
                print("currentDownLoadData = \(progress.totalUnitCount)")
                strongSelf.tsDataByte = progress.totalUnitCount
                let currentDownload = strongSelf.downLoadedDuration + tsModel.duration * Float(progress.fractionCompleted)
                let prog = currentDownload/strongSelf.tsListModel.duration
                strongSelf.progressUpdateHandler?(prog)
        }
        .responseData { [weak self] response in
            guard let strongSelf = self else { return }
            if let _ = response.result.value {
                let dataEnd = Date().timeIntervalSince(date)
                strongSelf.getCurrentTSDownloadTime(dataEnd)
                print("dataEnd == \(dataEnd)")
                if index == strongSelf.tsListModel.tsModelArray.count - 1 { // 最后一个
                    print("The last ts downloaded - create local .m3u8 文件")
                    strongSelf.createLocalM3U8file()
                    strongSelf.downloadSuccessHandler?()
                    return
                }
                print("第\(index)个下载完成, 继续下载第 \(index + 1)个")
                strongSelf.downLoadedDuration += tsModel.duration
                self?.downLoadIndex(index+1)
            }
            if let error = response.error {
                var failStr = ""
                if (error as NSError).code  == NSURLErrorCancelled {
                     strongSelf.resumeData = response.resumeData
                    failStr = "cancel - download"
                } else {
                    failStr = "failed - Network"
                    if strongSelf.retryTimes < 1 {  //重试下载
                        strongSelf.retryTimes += 1
                        strongSelf.downLoadIndex(index)
                    } else {
                        strongSelf.downloadFailHandler?(failStr)
                    }
                }
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
        try? writeData.write(to: filePath) 
    }
    
    func getCurrentTSDownloadTime(_ dateStart: TimeInterval) {
        if tsDataByte == 0 { return }
        var speedStr = "0KB/s"
        let speed = Double(tsDataByte)/dateStart
       
        if speed > 1024*1024 { // 超过 1.0M/s
            speedStr = String(format: "%.1fM/s", speed/1024/1024)
        } else if speed > 1024 {
            speedStr = String(format: "%dKB/s", Int(speed/1024))
        } else {
            speedStr = String(format: "%dB/s", Int(speed))
        }
        print("network speed = \(speed) speed str = \(speedStr)")
        networkSpeedUpdateHandler?(speedStr)
    }
}


